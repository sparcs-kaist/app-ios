#if os(iOS)
import UIKit
import TiptapKit

extension TiptapAttributedStringConverter {
  /// Builds editor text from a document, for editing an existing post. The inverse of
  /// ``document(from:)`` for everything the editor can express.
  ///
  /// Blocks the editor has no style for keep their content: a quote's paragraphs become body
  /// text, a bookmark becomes a link, and a divider is dropped.
  ///
  /// - Parameter attachment: Builds the attachment for an image node, or `nil` to drop it.
  public static func attributedString(
    from document: TiptapDocument,
    attachment: (TiptapNode) -> NSTextAttachment?
  ) -> NSAttributedString {
    withoutActuallyEscaping(attachment) { attachment in
      var builder = Builder(attachment: attachment)
      builder.appendBlocks(document.content, lists: [])
      return builder.result()
    }
  }
}

private struct Builder {
  let attachment: (TiptapNode) -> NSTextAttachment?
  /// Paragraphs, each without its terminating newline.
  var paragraphs: [NSAttributedString] = []

  init(attachment: @escaping (TiptapNode) -> NSTextAttachment?) {
    self.attachment = attachment
  }

  func result() -> NSAttributedString {
    let text = NSMutableAttributedString()
    for (index, paragraph) in paragraphs.enumerated() {
      if index > 0 {
        // The newline takes the attributes of the paragraph it ends.
        let previous = paragraphs[index - 1]
        let attributes = previous.length > 0
          ? previous.attributes(at: previous.length - 1, effectiveRange: nil)
          : TiptapBlockStyle.body.attributes
        text.append(NSAttributedString(string: "\n", attributes: attributes))
      }
      text.append(paragraph)
    }
    return text
  }

  // MARK: Blocks

  mutating func appendBlocks(_ nodes: [TiptapNode], lists: [NSTextList]) {
    for node in nodes {
      switch node.type {
      case .paragraph:
        appendInline(node.content, style: .body, lists: lists)
      case .heading:
        let style: TiptapBlockStyle = switch node[attribute: "level"]?.intValue ?? 1 {
        case 1: .title
        case 2: .heading
        default: .subheading
        }
        appendInline(node.content, style: style, lists: lists)
      case .codeBlock:
        let code = node.content.map { $0.type == .hardBreak ? "\n" : $0.text ?? "" }.joined()
        for line in code.components(separatedBy: "\n") {
          paragraphs.append(NSAttributedString(string: line, attributes: Self.attributes(.monospaced, lists: lists)))
        }
      case .bulletList, .orderedList:
        let list: NSTextList
        if node.type == .orderedList {
          list = NSTextList(markerFormat: .decimal, options: 0)
          list.startingItemNumber = node[attribute: "start"]?.intValue ?? 1
        } else {
          list = NSTextList(markerFormat: .disc, options: 0)
        }
        for item in node.content {
          let children = item.type == .listItem ? item.content : [item]
          appendBlocks(children, lists: lists + [list])
        }
      case .attachmentImage, .image, .linkBookmark, .text, .hardBreak:
        appendInline([node], style: .body, lists: lists)
      case .horizontalRule:
        break
      default:
        // A quote or an unknown container: keep what's inside.
        appendBlocks(node.content, lists: lists)
      }
    }
  }

  // MARK: Inline content

  /// Appends one paragraph, or several when images split it: each image sits on its own line.
  private mutating func appendInline(_ nodes: [TiptapNode], style: TiptapBlockStyle, lists: [NSTextList]) {
    let attributes = Self.attributes(style, lists: lists)
    var run = NSMutableAttributedString()
    var hasMedia = false

    func flush(_ builder: inout Builder, force: Bool = false) {
      if run.length > 0 || force {
        builder.paragraphs.append(run)
      }
      run = NSMutableAttributedString()
    }

    for node in nodes {
      switch node.type {
      case .text:
        run.append(NSAttributedString(string: node.text ?? "", attributes: Self.inlineAttributes(for: node.marks, base: attributes, style: style)))
      case .hardBreak:
        run.append(NSAttributedString(string: "\u{2028}", attributes: attributes))
      case .attachmentImage, .image:
        hasMedia = true
        flush(&self)
        if let attachment = attachment(node) {
          let image = NSMutableAttributedString(attachment: attachment)
          image.addAttributes(Self.attributes(.body, lists: lists), range: NSRange(location: 0, length: image.length))
          paragraphs.append(image)
        }
      case .linkBookmark:
        // The editor has no bookmark card; the link keeps the destination.
        guard let href = node[attribute: "href"]?.stringValue else { continue }
        var linkAttributes = attributes
        linkAttributes[.link] = URL(string: href) ?? href
        let title = node[attribute: "title"]?.stringValue.flatMap { $0.isEmpty ? nil : $0 } ?? href
        run.append(NSAttributedString(string: title, attributes: linkAttributes))
      default:
        let nested = Builder.inlineText(node.content, attributes: attributes, style: style)
        run.append(nested)
      }
    }
    // A paragraph with nothing in it is a deliberate blank line.
    flush(&self, force: !hasMedia)
  }

  private static func inlineText(_ nodes: [TiptapNode], attributes: [NSAttributedString.Key: Any], style: TiptapBlockStyle) -> NSAttributedString {
    let text = NSMutableAttributedString()
    for node in nodes {
      switch node.type {
      case .text:
        text.append(NSAttributedString(string: node.text ?? "", attributes: inlineAttributes(for: node.marks, base: attributes, style: style)))
      case .hardBreak:
        text.append(NSAttributedString(string: "\u{2028}", attributes: attributes))
      default:
        text.append(inlineText(node.content, attributes: attributes, style: style))
      }
    }
    return text
  }

  static func attributes(_ style: TiptapBlockStyle, lists: [NSTextList]) -> [NSAttributedString.Key: Any] {
    var attributes = style.attributes
    if !lists.isEmpty {
      let paragraph = NSMutableParagraphStyle()
      paragraph.textLists = lists
      paragraph.headIndent = 24 * CGFloat(lists.count)
      paragraph.firstLineHeadIndent = paragraph.headIndent
      attributes[.paragraphStyle] = paragraph
    }
    return attributes
  }

  static func inlineAttributes(
    for marks: [TiptapMark],
    base: [NSAttributedString.Key: Any],
    style: TiptapBlockStyle
  ) -> [NSAttributedString.Key: Any] {
    var attributes = base
    var font = base[.font] as? UIFont ?? style.font
    var traits = font.fontDescriptor.symbolicTraits
    for mark in marks {
      switch mark.type {
      case .bold: traits.insert(.traitBold)
      case .italic: traits.insert(.traitItalic)
      case .code:
        font = .monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
        traits = font.fontDescriptor.symbolicTraits
      case .underline: attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
      case .strike: attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
      case .link:
        if let href = mark[attribute: "href"]?.stringValue {
          attributes[.link] = URL(string: href) ?? href
        }
      case .textStyle:
        if let color = mark[attribute: "color"]?.stringValue.flatMap(UIColor.init(cssHex:)) {
          attributes[.foregroundColor] = color
        }
      default:
        break
      }
    }
    if traits != font.fontDescriptor.symbolicTraits,
       let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
      font = UIFont(descriptor: descriptor, size: font.pointSize)
    }
    attributes[.font] = font
    return attributes
  }
}

private extension UIColor {
  /// `#rgb` or `#rrggbb`.
  convenience init?(cssHex: String) {
    var hex = cssHex.trimmingCharacters(in: .whitespaces)
    guard hex.hasPrefix("#") else { return nil }
    hex.removeFirst()
    if hex.count == 3 {
      hex = String(hex.flatMap { [$0, $0] })
    }
    guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
    self.init(
      red: CGFloat((value >> 16) & 0xFF) / 255,
      green: CGFloat((value >> 8) & 0xFF) / 255,
      blue: CGFloat(value & 0xFF) / 255,
      alpha: 1
    )
  }
}
#endif
