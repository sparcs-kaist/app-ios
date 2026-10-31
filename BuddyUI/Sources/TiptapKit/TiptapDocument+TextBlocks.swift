import Foundation

extension TiptapDocument {
  /// The text of each paragraph and heading, in reading order, for processing a block at a time
  /// (e.g. translation). Line breaks within a block are `\n`. Code blocks are left out.
  public var textBlocks: [String] {
    var blocks: [String] = []
    Self.visitTextBlocks(content) { node in
      blocks.append(Self.inlineText(of: node.content))
    }
    return blocks
  }

  /// The document with the text of each block from ``textBlocks`` replaced, in order.
  ///
  /// The document's structure (headings, lists, quotes, images, bookmarks) is kept. A block's
  /// marks survive when its text was uniformly marked (a bold line, a link); text whose marks
  /// varied comes back unmarked, since the new text has no positions to map them onto.
  public func replacingTextBlocks(with replacements: [String]) -> TiptapDocument {
    var index = 0
    func rebuild(_ nodes: [TiptapNode]) -> [TiptapNode] {
      nodes.map { node in
        var node = node
        if node.type == .paragraph || node.type == .heading {
          defer { index += 1 }
          guard index < replacements.count else { return node }
          node.content = Self.replacingText(in: node.content, with: replacements[index])
        } else if node.type != .codeBlock {
          node.content = rebuild(node.content)
        }
        return node
      }
    }
    return TiptapDocument(content: rebuild(content))
  }

  // MARK: - Helpers

  private static func visitTextBlocks(_ nodes: [TiptapNode], _ visit: (TiptapNode) -> Void) {
    for node in nodes {
      switch node.type {
      case .paragraph, .heading:
        visit(node)
      case .codeBlock:
        break
      default:
        visitTextBlocks(node.content, visit)
      }
    }
  }

  private static func inlineText(of nodes: [TiptapNode]) -> String {
    nodes.map { node in
      switch node.type {
      case .text: node.text ?? ""
      case .hardBreak: "\n"
      default: inlineText(of: node.content)
      }
    }.joined()
  }

  /// Puts `text` in place of a block's text nodes, keeping its media (images, bookmarks) after it.
  private static func replacingText(in nodes: [TiptapNode], with text: String) -> [TiptapNode] {
    let textNodes = nodes.filter { $0.type == .text }
    let media = nodes.filter { $0.type != .text && $0.type != .hardBreak }
    let marks = textNodes.first.map { first in
      textNodes.allSatisfy { $0.marks == first.marks } ? first.marks : []
    } ?? []

    var rebuilt: [TiptapNode] = []
    for (lineIndex, line) in text.components(separatedBy: "\n").enumerated() {
      if lineIndex > 0 {
        rebuilt.append(TiptapNode(type: .hardBreak))
      }
      if !line.isEmpty {
        rebuilt.append(TiptapNode(type: .text, marks: marks, text: line))
      }
    }
    return rebuilt + media
  }
}
