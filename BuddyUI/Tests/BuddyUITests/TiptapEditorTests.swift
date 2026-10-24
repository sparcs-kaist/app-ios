import Foundation
import Testing
import UIKit
import TiptapKit
@testable import TiptapEditor

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

@MainActor
struct TiptapAttributedStringConverterTests {
  private let converter = TiptapAttributedStringConverter { attachment in
    guard attachment is TiptapImageAttachment else { return nil }
    return TiptapNode(type: .attachmentImage, attrs: ["src": .string("https://x/y.png")])
  }

  private func body(_ string: String, _ extra: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString {
    NSAttributedString(string: string, attributes: TiptapBlockStyle.body.attributes.merging(extra) { $1 })
  }

  private func styled(_ string: String, _ style: TiptapBlockStyle) -> NSAttributedString {
    NSAttributedString(string: string, attributes: style.attributes)
  }

  private func listed(_ string: String, _ lists: [NSTextList]) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.textLists = lists
    return body(string, [.paragraphStyle: paragraph])
  }

  private func join(_ parts: NSAttributedString...) -> NSAttributedString {
    let result = NSMutableAttributedString()
    parts.forEach(result.append)
    return result
  }

  @Test func mapsStylesToBlocksAndTrimsBlankEdges() {
    let text = join(body("\n"), styled("Big\n", .title), body("one\n\ntwo\n"), styled("let a = 1\n", .monospaced), styled("let b = 2\n", .monospaced), body("\n"))
    let content = converter.document(from: text).content
    #expect(content.map(\.type) == [.heading, .paragraph, .paragraph, .paragraph, .codeBlock])
    #expect(content[0][attribute: "level"]?.intValue == 1)
    #expect(content[2].content.isEmpty)
    #expect(content[4].content.first?.text == "let a = 1\nlet b = 2")
  }

  @Test func mapsFontTraitsAndAttributesToMarks() {
    let bold = UIFont.boldSystemFont(ofSize: 17)
    let text = join(
      body("plain "),
      body("bold", [.font: bold]),
      body(" link", [.link: URL(string: "https://sparcs.org")!, .underlineStyle: NSUnderlineStyle.single.rawValue]),
      body(" red", [.foregroundColor: UIColor.systemRed, .strikethroughStyle: 1])
    )
    let inline = converter.document(from: text).content[0].content
    #expect(inline.map(\.text) == ["plain ", "bold", " link", " red"])
    #expect(inline[1].marks.map(\.type) == [.bold])
    #expect(inline[2].marks.map(\.type) == [.underline, .link])
    #expect(inline[3].marks.map(\.type) == [.strike, .textStyle])
  }

  @Test func ignoresTheDefaultTextColour() {
    let inline = converter.document(from: body("x", [.foregroundColor: UIColor.black])).content[0].content
    #expect(inline[0].marks.isEmpty)
  }

  @Test func splitsLineSeparatorsIntoHardBreaks() {
    let inline = converter.document(from: body("a\u{2028}b")).content[0].content
    #expect(inline.map(\.type) == [.text, .hardBreak, .text])
  }

  @Test func rebuildsNestedLists() {
    let bullets = NSTextList(markerFormat: .disc, options: 0)
    let numbers = NSTextList(markerFormat: .decimal, options: 0)
    numbers.startingItemNumber = 3
    let text = join(
      listed("one\n", [bullets]),
      listed("nested\n", [bullets, numbers]),
      listed("two\n", [bullets]),
      body("after")
    )
    let content = converter.document(from: text).content
    #expect(content.map(\.type) == [.bulletList, .paragraph])

    let items = content[0].content
    #expect(items.count == 2)
    #expect(items[0].content.map(\.type) == [.paragraph, .orderedList])
    #expect(items[0].content[1][attribute: "start"]?.intValue == 3)
    #expect(items[0].content[1].content.first?.content.first?.content.first?.text == "nested")
    #expect(items[1].content.first?.content.first?.text == "two")
  }

  @Test func convertsPhotoAttachments() {
    let photo = NSMutableAttributedString(attachment: TiptapImageAttachment(image: UIImage(systemName: "star")!))
    let text = join(body("before\n"), photo, body("\nafter"))
    let content = converter.document(from: text).content
    #expect(content.count == 3)
    #expect(content[1].content.map(\.type) == [.attachmentImage])
  }

  @Test func inferBlockStyleFromFontWithoutTag() {
    #expect(TiptapBlockStyle.of([.font: TiptapBlockStyle.title.font]) == .title)
    #expect(TiptapBlockStyle.of([.font: UIFont.preferredFont(forTextStyle: .body)]) == .body)
  }
}

@MainActor
struct TiptapTextViewTests {
  /// A text view in a window, so it can become first responder and receive typing.
  private func makeTextView() -> (TiptapTextView, UIWindow, TiptapEditor.Coordinator) {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let view = TiptapTextView()
    let coordinator = TiptapEditor.Coordinator()
    view.delegate = coordinator
    view.frame = window.bounds
    window.addSubview(view)
    window.makeKeyAndVisible()
    _ = view.becomeFirstResponder()
    return (view, window, coordinator)
  }

  /// Types like the keyboard does: each Return is its own insertion, offered to the delegate
  /// first. (`insertText` from code skips `shouldChangeTextIn`; the keyboard doesn't.)
  private func type(_ text: String, into view: TiptapTextView) {
    for (index, line) in text.components(separatedBy: "\n").enumerated() {
      if index > 0, view.delegate?.textView?(view, shouldChangeTextIn: view.selectedRange, replacementText: "\n") ?? true {
        view.insertText("\n")
      }
      if !line.isEmpty { view.insertText(line) }
    }
  }

  private func paragraphStyles(_ view: TiptapTextView) -> [NSParagraphStyle?] {
    let text = view.textStorage
    let string = text.string as NSString
    var styles: [NSParagraphStyle?] = []
    string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byParagraphs) { _, range, _, _ in
      styles.append(text.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle)
    }
    return styles
  }

  @Test func returnOnAnEmptyItemEndsTheListWithoutItsIndent() {
    let (view, window, coordinator) = makeTextView()
    defer { withExtendedLifetime((window, coordinator)) {} }

    type("one", into: view)
    view.toggleBulletList()
    type("\ntwo\n\nafter", into: view)

    let styles = paragraphStyles(view)
    #expect(styles.map { $0?.textLists.count ?? 0 } == [1, 1, 0])
    #expect(styles.last??.headIndent == 0)
    #expect(styles.last??.firstLineHeadIndent == 0)
  }

  @Test func returnAfterAHeadingContinuesInBody() {
    let (view, window, coordinator) = makeTextView()
    defer { withExtendedLifetime((window, coordinator)) {} }

    view.typingAttributes = TiptapBlockStyle.heading.attributes
    type("Heading\nbody", into: view)

    let last = view.textStorage.attributes(at: view.textStorage.length - 1, effectiveRange: nil)
    #expect(TiptapBlockStyle.of(last) == .body)
  }
}
