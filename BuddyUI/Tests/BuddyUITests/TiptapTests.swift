import Foundation
import Testing
import TiptapKit

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
