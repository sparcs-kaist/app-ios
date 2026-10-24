import Foundation
import SwiftUI
import Testing
import TiptapKit
@testable import TiptapUI

struct TiptapParserTests {
  private let parser = TiptapParser()

  @Test func parsesStarterKitDocument() throws {
    let json = """
    {"type":"doc","content":[
      {"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Title"}]},
      {"type":"paragraph","content":[
        {"type":"text","text":"Hello "},
        {"type":"text","marks":[{"type":"bold"}],"text":"world"},
        {"type":"hardBreak"},
        {"type":"text","text":"again"}
      ]},
      {"type":"bulletList","content":[
        {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"one"}]}]}
      ]}
    ]}
    """
    let document = try parser.parse(json)
    #expect(document.content.map(\.type) == [.heading, .paragraph, .bulletList])
    #expect(document.content[0][attribute: "level"]?.intValue == 2)
    #expect(document.content[1].content[1].marks.map(\.type) == [.bold])
    #expect(document.plainText == "Title\nHello world\nagain\none")
  }

  @Test(arguments: ["<p>Hello</p>", "plain text", ""])
  func rejectsNonJSON(content: String) {
    #expect(throws: TiptapParseError.notJSON) { try parser.parse(content) }
  }

  @Test func rejectsBrokenJSON() {
    #expect(throws: TiptapParseError.malformed) { try parser.parse("{\"type\":\"doc\",") }
  }

  @Test func acceptsWrappedDocument() throws {
    let json = #"{"content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"x"}]}]}}"#
    #expect(try parser.parse(json).plainText == "x")
  }

  /// What the Ara server stores after bleach's `linkify` runs over the JSON string.
  @Test func repairsLinkifiedURLs() throws {
    let json = """
    {"type":"doc","content":[{"type":"paragraph","content":[
      {"type":"text","marks":[{"type":"link","attrs":{"href":"<a href="https://sparcs.org/?a=1&amp;b=2" rel="nofollow">https://sparcs.org/?a=1&amp;b=2</a>"}}],"text":"see <a href="https://sparcs.org" rel="nofollow">https://sparcs.org</a> now"},
      {"type":"attachmentImage","attrs":{"src":"<a href="https://newara.cdn.sparcs.org/a.png" rel="nofollow">https://newara.cdn.sparcs.org/a.png</a>","width":250}}
    ]}]}
    """
    let paragraph = try #require(try parser.parse(json).content.first)
    #expect(paragraph.content[0].text == "see https://sparcs.org now")
    #expect(paragraph.content[0].marks[0][attribute: "href"]?.stringValue == "https://sparcs.org/?a=1&b=2")
    #expect(paragraph.content[1][attribute: "src"]?.stringValue == "https://newara.cdn.sparcs.org/a.png")
  }

  @Test func strictParserDoesNotRepair() {
    let json = #"{"type":"doc","content":[{"type":"text","text":"<a href="https://x.org">https://x.org</a>"}]}"#
    #expect(throws: TiptapParseError.malformed) { try TiptapParser(options: .strict).parse(json) }
  }

  @Test func decodesHTMLEntitiesInText() throws {
    let json = #"{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"A &amp; B &lt;3 &#54620;&#xAE00; &bogus; &"}]}]}"#
    #expect(try parser.parse(json).plainText == "A & B <3 한글 &bogus; &")
  }

  @Test func toleratesUnknownNodesAndOddAttributes() throws {
    let json = #"{"type":"doc","content":[{"type":"callout","attrs":{"level":"3","x":[1,{"y":null}]},"content":[{"type":"paragraph","content":[{"type":"text","text":"inside"}]}]}]}"#
    let document = try parser.parse(json)
    #expect(document.content[0].type == "callout")
    #expect(document.content[0][attribute: "level"]?.intValue == 3)
    #expect(document.plainText == "inside")
  }
}

struct TiptapLayoutTests {
  private func layout(_ json: String, baseURL: URL? = nil) throws -> TiptapLayout {
    TiptapLayout(document: try TiptapParser().parse(json), baseURL: baseURL)
  }

  @Test func liftsInlineMediaOutOfParagraphs() throws {
    let layout = try layout("""
    {"type":"doc","content":[{"type":"paragraph","content":[
      {"type":"text","text":"before"},
      {"type":"attachmentImage","attrs":{"src":"/media/a.png","width":250}},
      {"type":"hardBreak"},
      {"type":"linkBookmark","attrs":{"href":"https://news.kaist.ac.kr/x","title":"https://news.kaist.ac.kr/x"}},
      {"type":"text","text":"after"}
    ]}]}
    """, baseURL: URL(string: "https://newara.sparcs.org"))

    #expect(layout.blocks.count == 4)
    guard case .paragraph(let before) = layout.blocks[0].kind,
          case .image(let image) = layout.blocks[1].kind,
          case .bookmark(let bookmark) = layout.blocks[2].kind,
          case .paragraph(let after) = layout.blocks[3].kind else {
      Issue.record("Unexpected blocks: \(layout.blocks.map(\.kind))")
      return
    }
    #expect(String(before.characters) == "before")
    #expect(image.url.absoluteString == "https://newara.sparcs.org/media/a.png")
    #expect(image.width == 250)
    #expect(bookmark.displayTitle == "KAIST")
    #expect(String(after.characters) == "after")
  }

  @Test func trimsOuterBlankParagraphsButKeepsInnerOnes() throws {
    let layout = try layout("""
    {"type":"doc","content":[{"type":"paragraph"},{"type":"paragraph","content":[{"type":"text","text":"a"}]},{"type":"paragraph"},{"type":"paragraph","content":[{"type":"text","text":"b"}]},{"type":"paragraph"}]}
    """)
    #expect(layout.blocks.map(\.isEmptyParagraph) == [false, true, false])
  }

  @Test func appliesMarks() throws {
    let layout = try layout("""
    {"type":"doc","content":[{"type":"paragraph","content":[
      {"type":"text","marks":[{"type":"bold"},{"type":"italic"},{"type":"link","attrs":{"href":"https://sparcs.org"}}],"text":"x"},
      {"type":"text","marks":[{"type":"link","attrs":{"href":"javascript:alert(1)"}}],"text":"y"}
    ]}]}
    """)
    guard case .paragraph(let text) = try #require(layout.blocks.first).kind else {
      Issue.record("Expected a paragraph")
      return
    }
    let runs = Array(text.runs)
    #expect(runs[0].inlinePresentationIntent == [.stronglyEmphasized, .emphasized])
    #expect(runs[0].link == URL(string: "https://sparcs.org"))
    #expect(runs[1].link == nil)
  }

  @Test func numbersOrderedListsFromStart() throws {
    let layout = try layout("""
    {"type":"doc","content":[{"type":"orderedList","attrs":{"start":3},"content":[
      {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"a"}]}]},
      {"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"b"}]},
        {"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"c"}]}]}]}]}
    ]}]}
    """)
    guard case .list(let list) = try #require(layout.blocks.first).kind,
          case .list(let nested) = try #require(list.items.last?.blocks.last).kind else {
      Issue.record("Expected nested lists")
      return
    }
    #expect(list.items.map(\.marker) == ["3.", "4."])
    #expect(nested.items.map(\.marker) == ["◦"])
  }

  @Test func blockIDsAreUnique() throws {
    let layout = try layout("""
    {"type":"doc","content":[{"type":"blockquote","content":[{"type":"paragraph","content":[{"type":"text","text":"q"}]}]},
      {"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"a"}]}]}]},
      {"type":"codeBlock","content":[{"type":"text","text":"let x = 1"}]},{"type":"horizontalRule"}]}
    """)
    var ids: [Int] = []
    func collect(_ blocks: [TiptapBlock]) {
      for block in blocks {
        ids.append(block.id)
        switch block.kind {
        case .blockquote(let children): collect(children)
        case .list(let list):
          for item in list.items {
            ids.append(item.id)
            collect(item.blocks)
          }
        default: break
        }
      }
    }
    collect(layout.blocks)
    #expect(Set(ids).count == ids.count)
  }

  @Test(arguments: [
    ("#e03131", true), ("#000000", false), ("#fff", false), ("rgb(34, 139, 230)", true), ("red", false),
  ])
  func parsesOnlyReadableColours(css: String, isApplied: Bool) {
    #expect((TiptapColor.parse(css) != nil) == isApplied)
  }
}
