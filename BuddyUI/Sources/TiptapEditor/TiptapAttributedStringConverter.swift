#if os(iOS)
import UIKit
import TiptapKit

/// Converts the editor's attributed text into a Tiptap document Ara can store.
///
/// - Paragraph styles become `heading` / `paragraph` / `codeBlock` (consecutive monospaced
///   paragraphs join into one code block).
/// - `NSTextList`s become nested `bulletList` / `orderedList`s.
/// - Font traits, underline, strikethrough, links and colours become marks.
/// - Attachments become whatever `attachmentNode` returns, typically an `attachmentImage`.
public struct TiptapAttributedStringConverter {
  /// Builds the node for an attachment, or `nil` to drop it.
  public var attachmentNode: (NSTextAttachment) -> TiptapNode?

  public init(attachmentNode: @escaping (NSTextAttachment) -> TiptapNode?) {
    self.attachmentNode = attachmentNode
  }

  public func document(from text: NSAttributedString) -> TiptapDocument {
    let paragraphs = self.paragraphs(in: text)
    let blocks = Self.mergingCodeBlocks(paragraphs)
    return TiptapDocument(content: Self.nest(blocks[...], depth: 0))
  }

  // MARK: - Paragraphs

  /// A converted paragraph and the lists it sits in, outermost first.
  struct Block {
    var node: TiptapNode
    var lists: [NSTextList]
    var style: TiptapBlockStyle
  }

  private func paragraphs(in text: NSAttributedString) -> [Block] {
    let string = text.string as NSString
    var blocks: [Block] = []
    string.enumerateSubstrings(
      in: NSRange(location: 0, length: string.length),
      options: [.byParagraphs, .substringNotRequired]
    ) { _, range, _, _ in
      blocks.append(self.block(for: text, range: range))
    }
    // A trailing newline leaves an empty paragraph the enumeration doesn't report; it's
    // dropped with the other blank edges anyway.
    return Self.trimmingBlankEdges(blocks)
  }

  private func block(for text: NSAttributedString, range: NSRange) -> Block {
    // An empty paragraph has no characters of its own; its style is on its terminator.
    let styleLocation = min(range.location, max(text.length - 1, 0))
    let attributes = text.length > 0 ? text.attributes(at: styleLocation, effectiveRange: nil) : [:]
    let style = TiptapBlockStyle.of(attributes)
    let lists = (attributes[.paragraphStyle] as? NSParagraphStyle)?.textLists ?? []

    switch style {
    case .monospaced:
      let code = text.attributedSubstring(from: range).string.replacingOccurrences(of: "\u{2028}", with: "\n")
      return Block(node: Self.codeBlock(code), lists: lists, style: style)
    case .title, .heading, .subheading:
      let inline = inlineNodes(in: text, range: range, style: style)
      return Block(
        node: TiptapNode(type: .heading, attrs: ["level": .number(Double(style.headingLevel ?? 1))], content: inline),
        lists: lists,
        style: style
      )
    case .body:
      return Block(node: TiptapNode(type: .paragraph, content: inlineNodes(in: text, range: range, style: style)), lists: lists, style: style)
    }
  }

  private func inlineNodes(in text: NSAttributedString, range: NSRange, style: TiptapBlockStyle) -> [TiptapNode] {
    var nodes: [TiptapNode] = []
    text.enumerateAttributes(in: range) { attributes, runRange, _ in
      if let attachment = attributes[.attachment] as? NSTextAttachment {
        if let node = attachmentNode(attachment) {
          nodes.append(node)
        }
        return
      }
      let marks = Self.marks(for: attributes, style: style)
      let run = (text.string as NSString).substring(with: runRange)
      // Shift-Return inserts a line separator: a line break within the paragraph.
      for (index, line) in run.components(separatedBy: "\u{2028}").enumerated() {
        if index > 0 {
          nodes.append(TiptapNode(type: .hardBreak))
        }
        guard !line.isEmpty else { continue }
        // Neighbouring runs with the same marks (split by an attribute Tiptap doesn't store) merge.
        if let last = nodes.last, last.type == .text, last.marks == marks {
          nodes[nodes.count - 1].text = (last.text ?? "") + line
        } else {
          nodes.append(TiptapNode(type: .text, marks: marks, text: line))
        }
      }
    }
    return nodes
  }

  static func marks(for attributes: [NSAttributedString.Key: Any], style: TiptapBlockStyle) -> [TiptapMark] {
    var marks: [TiptapMark] = []
    if let font = attributes[.font] as? UIFont {
      let traits = font.fontDescriptor.symbolicTraits
      // A heading's own weight isn't bold text.
      if traits.contains(.traitBold), style == .body { marks.append(TiptapMark(type: .bold)) }
      if traits.contains(.traitItalic) { marks.append(TiptapMark(type: .italic)) }
      if traits.contains(.traitMonoSpace), style != .monospaced { marks.append(TiptapMark(type: .code)) }
    }
    if let underline = attributes[.underlineStyle] as? Int, underline != 0 {
      marks.append(TiptapMark(type: .underline))
    }
    if let strikethrough = attributes[.strikethroughStyle] as? Int, strikethrough != 0 {
      marks.append(TiptapMark(type: .strike))
    }
    if let color = attributes[.foregroundColor] as? UIColor, let hex = Self.hex(for: color) {
      marks.append(TiptapMark(type: .textStyle, attrs: ["color": .string(hex)]))
    }
    let link = (attributes[.link] as? URL)?.absoluteString ?? attributes[.link] as? String
    if let link, !link.isEmpty {
      marks.append(TiptapMark(type: .link, attrs: ["href": .string(link)]))
    }
    return marks
  }

  /// The colour as `#rrggbb`, or `nil` for the default text colour. Near-black and near-white
  /// are treated as default too: they come from pasted text and only mean "normal".
  static func hex(for color: UIColor) -> String? {
    let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha), alpha > 0 else { return nil }
    let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    guard (0.12...0.9).contains(luminance) else { return nil }
    let channel = { (value: CGFloat) in Int((min(max(value, 0), 1) * 255).rounded()) }
    return String(format: "#%02x%02x%02x", channel(red), channel(green), channel(blue))
  }

  // MARK: - Structure

  private static func codeBlock(_ code: String) -> TiptapNode {
    TiptapNode(type: .codeBlock, content: code.isEmpty ? [] : [TiptapNode(type: .text, text: code)])
  }

  private static func isBlank(_ block: Block) -> Bool {
    block.lists.isEmpty && block.node.content.isEmpty
  }

  private static func trimmingBlankEdges(_ blocks: [Block]) -> [Block] {
    guard let first = blocks.firstIndex(where: { !isBlank($0) }),
          let last = blocks.lastIndex(where: { !isBlank($0) }) else { return [] }
    return Array(blocks[first...last])
  }

  /// Joins consecutive monospaced paragraphs at the same list position into one code block.
  static func mergingCodeBlocks(_ blocks: [Block]) -> [Block] {
    var merged: [Block] = []
    for block in blocks {
      if block.style == .monospaced, let last = merged.last, last.style == .monospaced, last.lists == block.lists {
        let previous = last.node.content.first?.text ?? ""
        let next = block.node.content.first?.text ?? ""
        merged[merged.count - 1].node = codeBlock(previous + "\n" + next)
      } else {
        merged.append(block)
      }
    }
    return merged
  }

  /// Rebuilds list nesting from each paragraph's list path. A paragraph `depth + 1` lists deep
  /// starts a new item; deeper paragraphs that follow it nest inside that item.
  static func nest(_ blocks: ArraySlice<Block>, depth: Int) -> [TiptapNode] {
    var nodes: [TiptapNode] = []
    var index = blocks.startIndex
    while index < blocks.endIndex {
      let block = blocks[index]
      guard block.lists.count > depth else {
        nodes.append(block.node)
        index += 1
        continue
      }

      // The run of paragraphs inside this list.
      let list = block.lists[depth]
      var end = index
      while end < blocks.endIndex, blocks[end].lists.count > depth, blocks[end].lists[depth] == list {
        end += 1
      }

      var items: [TiptapNode] = []
      var itemStart = index
      while itemStart < end {
        var itemEnd = itemStart + 1
        while itemEnd < end, blocks[itemEnd].lists.count > depth + 1 {
          itemEnd += 1
        }
        let head = blocks[itemStart].lists.count == depth + 1
          ? [blocks[itemStart].node] + nest(blocks[(itemStart + 1)..<itemEnd], depth: depth + 1)
          : nest(blocks[itemStart..<itemEnd], depth: depth + 1)
        items.append(TiptapNode(type: .listItem, content: head))
        itemStart = itemEnd
      }

      nodes.append(listNode(for: list, items: items))
      index = end
    }
    return nodes
  }

  private static func listNode(for list: NSTextList, items: [TiptapNode]) -> TiptapNode {
    let ordered: Set<NSTextList.MarkerFormat> = [
      .decimal, .octal, .lowercaseAlpha, .uppercaseAlpha, .lowercaseRoman, .uppercaseRoman,
      .lowercaseLatin, .uppercaseLatin, .lowercaseHexadecimal, .uppercaseHexadecimal,
    ]
    guard ordered.contains(list.markerFormat) else {
      return TiptapNode(type: .bulletList, content: items)
    }
    let start = list.startingItemNumber
    return TiptapNode(
      type: .orderedList,
      attrs: start == 1 ? [:] : ["start": .number(Double(start))],
      content: items
    )
  }
}
#endif
