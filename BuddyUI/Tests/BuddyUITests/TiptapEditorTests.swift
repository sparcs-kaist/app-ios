import Foundation
import Testing
import TiptapKit

struct TiptapJSONWriterTests {
  private let document = TiptapDocument(content: [
    TiptapNode(type: .heading, attrs: ["level": .number(2)], content: [TiptapNode(type: .text, text: "Title")]),
    TiptapNode(type: .paragraph, content: [
      TiptapNode(type: .text, marks: [TiptapMark(type: .link, attrs: ["href": .string("https://sparcs.org/a?b=1&c=2")])], text: "see sparcs.org"),
      TiptapNode(type: .hardBreak),
      TiptapNode(type: .text, marks: [TiptapMark(type: .bold)], text: "A & B <3 \"quoted\" \\ 한글"),
    ]),
    TiptapNode(type: .attachmentImage, attrs: ["src": .string("https://newara.cdn.sparcs.org/x.png"), "width": .number(500), "data-attachment": .number(7)]),
  ])

  @Test func roundTripsThroughTheParser() throws {
    let json = document.jsonString()
    #expect(try TiptapParser(options: .strict).parse(json) == document)
  }

  /// bleach's clean escapes &, < and >, and its linkify wraps anything URL- or domain-shaped.
  @Test func leavesNothingForASanitiserToChange() {
    let json = document.jsonString()
    #expect(!json.contains("&"))
    #expect(!json.contains("<"))
    #expect(!json.contains(">"))
    #expect(!json.contains("."))
    #expect(!json.contains("/"))
    #expect(json.hasPrefix("{\"type\":\"doc\""))
  }

  @Test func plainOutputIsReadable() {
    #expect(document.jsonString(sanitizerSafe: false).contains("https://sparcs.org/a?b=1&c=2"))
  }
}
