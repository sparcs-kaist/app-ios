import Foundation

extension TiptapDocument {
  /// The document's text with one line per text block, for summarising, translation
  /// and search. Images and bookmarks are left out, matching the Ara server's extractor.
  public var plainText: String {
    var lines: [String] = []
    Self.collectLines(from: content, into: &lines)
    return lines.joined(separator: "\n")
  }

  private static func collectLines(from nodes: [TiptapNode], into lines: inout [String]) {
    for node in nodes {
      if node.type.isTextblock || node.type == .text || node.type == .hardBreak {
        var line = ""
        appendInlineText(of: node, to: &line)
        lines.append(line)
      } else {
        collectLines(from: node.content, into: &lines)
      }
    }
  }

  private static func appendInlineText(of node: TiptapNode, to line: inout String) {
    switch node.type {
    case .text:
      line += node.text ?? ""
    case .hardBreak:
      line += "\n"
    case .attachmentImage, .image, .linkBookmark:
      break
    default:
      for child in node.content {
        appendInlineText(of: child, to: &line)
      }
    }
  }
}
