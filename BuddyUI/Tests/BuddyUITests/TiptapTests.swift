import Foundation
import SwiftUI
import Testing
import TiptapKit
@testable import TiptapUI

struct TiptapParserTests {
  private let parser = TiptapParser()

  /// Attributes come from whoever wrote the post; a number too big for `Int` mustn't trap.
  @Test func readsHugeNumbersWithoutTrapping() {
    let value = TiptapValue.number(1e300)
    #expect(value.intValue == nil)
    #expect(value.stringValue == String(1e300))
    #expect(TiptapValue.number(3).stringValue == "3")
    #expect(TiptapValue.number(2.5).intValue == 2)
  }

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

struct TiptapTextBlockTests {
  private let document = try! TiptapParser().parse("""
  {"type":"doc","content":[
    {"type":"heading","attrs":{"level":2},"content":[{"type":"text","marks":[{"type":"bold"}],"text":"안녕"}]},
    {"type":"paragraph","content":[{"type":"text","text":"첫 줄"},{"type":"hardBreak"},{"type":"text","marks":[{"type":"italic"}],"text":"둘째 줄"}]},
    {"type":"codeBlock","content":[{"type":"text","text":"let a = 1"}]},
    {"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"항목"}]}]}]},
    {"type":"paragraph","content":[{"type":"attachmentImage","attrs":{"src":"https://x.org/a.png"}}]}
  ]}
  """)

  @Test func listsTextBlocksInReadingOrderSkippingCode() {
    #expect(document.textBlocks == ["안녕", "첫 줄\n둘째 줄", "항목", ""])
  }

  /// Simulates a translator that keeps attribute runs: each run's text changes, its attributes don't.
  @Test func attributedBlocksKeepMarksPerRun() {
    let document = try! TiptapParser().parse("""
    {"type":"doc","content":[{"type":"paragraph","content":[
      {"type":"text","text":"설문 참여를 원하시면 "},
      {"type":"text","marks":[{"type":"link","attrs":{"href":"https://forms.gle/x"}},{"type":"underline"}],"text":"링크"},
      {"type":"text","text":"를 눌러 주세요"}
    ]}]}
    """)
    let source = document.attributedTextBlocks
    var translated = AttributedString()
    for (run, english) in zip(source.blocks[0].runs, ["To take part, tap ", "the link", " please"]) {
      var piece = AttributedString(english)
      piece.setAttributes(run.attributes)
      translated.append(piece)
    }
    let result = document.replacingTextBlocks(with: [translated], source: source)
    let inline = result.content[0].content
    #expect(inline.map(\.text) == ["To take part, tap ", "the link", " please"])
    #expect(inline[1].marks.map(\.type) == [.link, .underline])
    #expect(inline[1].marks[0][attribute: "href"]?.stringValue == "https://forms.gle/x")
  }

  /// A translator that returns plain text: each phrase's formatting is found again by its own
  /// translation, or by its original text (a URL), and phrases that can't be found stay plain.
  @Test func restoresMarksOntoPlainTranslations() {
    let document = try! TiptapParser().parse("""
    {"type":"doc","content":[{"type":"paragraph","content":[
      {"type":"text","marks":[{"type":"bold"}],"text":"설문"},
      {"type":"text","text":" 참여는 "},
      {"type":"text","marks":[{"type":"link","attrs":{"href":"https://forms.gle/x"}}],"text":"링크"},
      {"type":"text","text":" 또는 "},
      {"type":"text","marks":[{"type":"link","attrs":{"href":"https://sparcs.org"}}],"text":"https://sparcs.org"},
      {"type":"text","text":" "},
      {"type":"text","marks":[{"type":"italic"}],"text":"사라짐"}
    ]}]}
    """)
    let source = document.attributedTextBlocks
    let runs = source.markedRuns(inBlock: 0)
    #expect(runs.map(\.text) == ["설문", "링크", "https://sparcs.org", "사라짐"])

    let restored = TiptapAttributedTextBlocks.restoringMarks(
      zip(runs, ["Survey", "Link", "https://sparcs.org", "Vanished"]).map { (run: $0, translation: $1) },
      onto: "For the survey, use the link or https://sparcs.org."
    )
    let inline = document.replacingTextBlocks(with: [restored], source: source).content[0].content
    let marked = inline.filter { !$0.marks.isEmpty }
    #expect(marked.map(\.text) == ["survey", "link", "https://sparcs.org"])
    #expect(marked.map { $0.marks.first?.type } == [.bold, .link, .link])
    #expect(marked[1].marks.first?[attribute: "href"]?.stringValue == "https://forms.gle/x")
  }

  /// If only standard attributes survive, links and bold still come back.
  @Test func standardAttributesAreAFallback() {
    let document = try! TiptapParser().parse("""
    {"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"굵게"}]}]}
    """)
    var translated = AttributedString("Bold")
    translated.inlinePresentationIntent = .stronglyEmphasized
    let result = document.replacingTextBlocks(with: [translated], source: document.attributedTextBlocks)
    #expect(result.content[0].content.first?.marks.map(\.type) == [.bold])
  }

  @Test func replacesTextKeepingStructureAndUniformMarks() {
    let replaced = document.replacingTextBlocks(with: ["Hello", "First line\nSecond line", "Item", ""])
    #expect(replaced.textBlocks == ["Hello", "First line\nSecond line", "Item", ""])
    #expect(replaced.content.map(\.type) == [.heading, .paragraph, .codeBlock, .bulletList, .paragraph])
    // The heading was all bold, so it stays bold; the paragraph's marks varied, so they go.
    #expect(replaced.content[0].content.first?.marks.map(\.type) == [.bold])
    #expect(replaced.content[1].content.map(\.type) == [.text, .hardBreak, .text])
    #expect(replaced.content[1].content.allSatisfy { $0.marks.isEmpty })
    #expect(replaced.content[2] == document.content[2])
    #expect(replaced.content[4] == document.content[4])
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

  @Test func collectsImagesInReadingOrderIncludingNested() throws {
    let layout = try layout("""
    {"type":"doc","content":[
      {"type":"paragraph","content":[{"type":"attachmentImage","attrs":{"src":"https://x.org/1.png"}}]},
      {"type":"blockquote","content":[{"type":"paragraph","content":[{"type":"attachmentImage","attrs":{"src":"https://x.org/2.png"}}]}]},
      {"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"attachmentImage","attrs":{"src":"https://x.org/3.png"}}]}]}]}
    ]}
    """)
    #expect(layout.images.map(\.url.lastPathComponent) == ["1.png", "2.png", "3.png"])
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
