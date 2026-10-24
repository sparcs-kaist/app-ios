import SwiftUI
import TiptapKit

/// A Tiptap document flattened into render-ready blocks.
///
/// Building the layout resolves URLs, merges inline runs into `AttributedString`s and
/// lifts inline media (Ara's images and bookmarks) out into blocks of their own. It is
/// pure and `Sendable`, so callers can build it off the main actor and hand the views
/// nothing but finished values.
public struct TiptapLayout: Sendable, Equatable {
  public var blocks: [TiptapBlock]

  /// - Parameter baseURL: Resolves relative image sources and links.
  public init(document: TiptapDocument, baseURL: URL? = nil) {
    var builder = Builder(baseURL: baseURL)
    blocks = Self.trimmingEmptyParagraphs(builder.blocks(for: document.content, depth: 0))
  }

  public var isEmpty: Bool {
    blocks.isEmpty
  }

  /// Editors leave blank paragraphs around a document; only the inner ones are intentional spacing.
  private static func trimmingEmptyParagraphs(_ blocks: [TiptapBlock]) -> [TiptapBlock] {
    let isContent = { (block: TiptapBlock) in !block.isEmptyParagraph }
    guard let first = blocks.firstIndex(where: isContent),
          let last = blocks.lastIndex(where: isContent) else { return [] }
    return Array(blocks[first...last])
  }
}

public struct TiptapBlock: Identifiable, Sendable, Equatable {
  public enum Kind: Sendable, Equatable {
    case paragraph(AttributedString)
    case heading(level: Int, AttributedString)
    case codeBlock(code: String, language: String?)
    case image(TiptapImage)
    case bookmark(TiptapBookmark)
    case blockquote([TiptapBlock])
    case list(TiptapList)
    case horizontalRule
  }

  /// Unique within its layout.
  public let id: Int
  public let kind: Kind

  var isEmptyParagraph: Bool {
    if case .paragraph(let text) = kind {
      return text.characters.allSatisfy(\.isWhitespace)
    }
    return false
  }
}

public struct TiptapImage: Sendable, Hashable {
  public let url: URL
  public let alt: String?
  /// The width chosen in the editor, in points; `nil` to fill the available width.
  public let width: CGFloat?
}

public struct TiptapBookmark: Sendable, Hashable {
  public let url: URL
  public let title: String?

  /// Mirrors the Ara web client: a URL-shaped title becomes its most specific
  /// meaningful domain label (`https://news.kaist.ac.kr` → `KAIST`).
  public var displayTitle: String {
    guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
      return "URL"
    }
    guard let host = URL(string: title)?.host() ?? URL(string: "https://\(title)")?.host(),
          host.contains(".") else { return title }
    let labels = host.split(separator: ".").dropLast().reversed()
    return labels.first(where: { $0.count > 2 }).map { $0.uppercased() } ?? title
  }
}

public struct TiptapList: Sendable, Equatable {
  public struct Item: Identifiable, Sendable, Equatable {
    public let id: Int
    /// "•" or "3." — precomputed so rendering doesn't need the item's position.
    public let marker: String
    public let blocks: [TiptapBlock]
  }

  public let isOrdered: Bool
  public let items: [Item]
}

// MARK: - Builder

private struct Builder {
  let baseURL: URL?
  private var nextID = 0

  init(baseURL: URL?) {
    self.baseURL = baseURL
  }

  private static let bullets = ["•", "◦", "▪"]
  private static let linkSchemes: Set<String> = ["http", "https", "mailto", "tel"]

  private mutating func makeBlock(_ kind: TiptapBlock.Kind) -> TiptapBlock {
    defer { nextID += 1 }
    return TiptapBlock(id: nextID, kind: kind)
  }

  mutating func blocks(for nodes: [TiptapNode], depth: Int) -> [TiptapBlock] {
    var blocks: [TiptapBlock] = []
    blocks.reserveCapacity(nodes.count)
    for node in nodes {
      append(node, depth: depth, to: &blocks)
    }
    return blocks
  }

  private mutating func append(_ node: TiptapNode, depth: Int, to blocks: inout [TiptapBlock]) {
    switch node.type {
    case .paragraph:
      appendInline(node.content, to: &blocks, wrap: TiptapBlock.Kind.paragraph)

    case .heading:
      let level = min(max(node[attribute: "level"]?.intValue ?? 1, 1), 3)
      appendInline(node.content, to: &blocks) { .heading(level: level, $0) }

    case .codeBlock:
      var code = ""
      for child in node.content {
        code += child.type == .hardBreak ? "\n" : child.text ?? ""
      }
      let language = node[attribute: "language"]?.stringValue
      blocks.append(makeBlock(.codeBlock(code: code, language: language)))

    case .blockquote:
      let children = self.blocks(for: node.content, depth: depth)
      if !children.isEmpty {
        blocks.append(makeBlock(.blockquote(children)))
      }

    case .bulletList, .orderedList:
      let isOrdered = node.type == .orderedList
      let start = node[attribute: "start"]?.intValue ?? 1
      var items: [TiptapList.Item] = []
      for (offset, item) in node.content.enumerated() {
        // A stray non-`listItem` child is still shown as an item rather than dropped.
        let children = item.type == .listItem ? item.content : [item]
        let marker = isOrdered ? "\(start + offset)." : Self.bullets[depth % Self.bullets.count]
        let itemBlocks = self.blocks(for: children, depth: depth + 1)
        items.append(TiptapList.Item(id: nextID, marker: marker, blocks: itemBlocks))
        nextID += 1
      }
      if !items.isEmpty {
        blocks.append(makeBlock(.list(TiptapList(isOrdered: isOrdered, items: items))))
      }

    case .horizontalRule:
      blocks.append(makeBlock(.horizontalRule))

    case .text, .hardBreak, .attachmentImage, .image, .linkBookmark:
      // Inline content at block level; schemas allow it for Ara's inline media.
      appendInline([node], to: &blocks, wrap: TiptapBlock.Kind.paragraph)

    default:
      // An unknown container: keep its content rather than losing it.
      for child in node.content {
        append(child, depth: depth, to: &blocks)
      }
    }
  }

  // MARK: Inline content

  /// Merges inline nodes into text blocks, splitting around media, which can't live inside `Text`.
  private mutating func appendInline(
    _ nodes: [TiptapNode],
    to blocks: inout [TiptapBlock],
    wrap: (AttributedString) -> TiptapBlock.Kind
  ) {
    var run = AttributedString()
    var hasMedia = false

    func flush(_ builder: inout Builder) {
      // Line breaks left over beside an image are layout noise, not content.
      if !run.characters.isEmpty, !(hasMedia && run.characters.allSatisfy(\.isWhitespace)) {
        blocks.append(builder.makeBlock(wrap(run)))
      }
      run = AttributedString()
    }

    func visit(_ nodes: [TiptapNode], _ builder: inout Builder) {
      for node in nodes {
        switch node.type {
        case .text:
          run.append(builder.styledText(node))
        case .hardBreak:
          run.append(AttributedString("\n"))
        case .attachmentImage, .image:
          hasMedia = true
          flush(&builder)
          if let image = builder.image(from: node) {
            blocks.append(builder.makeBlock(.image(image)))
          }
        case .linkBookmark:
          hasMedia = true
          flush(&builder)
          if let url = builder.resolveURL(node[attribute: "href"]?.stringValue) {
            let title = node[attribute: "title"]?.stringValue
            blocks.append(builder.makeBlock(.bookmark(TiptapBookmark(url: url, title: title))))
          }
        default:
          visit(node.content, &builder)
        }
      }
    }

    visit(nodes, &self)
    if !hasMedia && run.characters.isEmpty {
      // An empty paragraph is a deliberate blank line.
      blocks.append(makeBlock(wrap(run)))
    } else {
      flush(&self)
    }
  }

  private func styledText(_ node: TiptapNode) -> AttributedString {
    var text = AttributedString(node.text ?? "")
    guard !node.marks.isEmpty else { return text }

    var intent: InlinePresentationIntent = []
    for mark in node.marks {
      switch mark.type {
      case .bold: intent.insert(.stronglyEmphasized)
      case .italic: intent.insert(.emphasized)
      case .strike: intent.insert(.strikethrough)
      case .code: intent.insert(.code)
      case .underline: text.swiftUI.underlineStyle = .single
      case .link:
        if let url = resolveURL(mark[attribute: "href"]?.stringValue) {
          text.link = url
        }
      case .textStyle:
        if let color = TiptapColor.parse(mark[attribute: "color"]?.stringValue) {
          text.swiftUI.foregroundColor = color
        }
      case .highlight:
        if let color = TiptapColor.parse(mark[attribute: "color"]?.stringValue, allowsExtremes: true) {
          text.swiftUI.backgroundColor = color.opacity(0.35)
        }
      default:
        break
      }
    }
    if !intent.isEmpty {
      text.inlinePresentationIntent = intent
    }
    return text
  }

  private func image(from node: TiptapNode) -> TiptapImage? {
    guard let url = resolveURL(node[attribute: "src"]?.stringValue) else { return nil }
    let width = node[attribute: "width"]?.doubleValue.flatMap { $0 > 0 ? CGFloat($0) : nil }
    let alt = node[attribute: "alt"]?.stringValue ?? node[attribute: "title"]?.stringValue
    return TiptapImage(url: url, alt: alt, width: width)
  }

  func resolveURL(_ raw: String?) -> URL? {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }

    let url: URL? = if raw.lowercased().hasPrefix("www.") {
      URL(string: "https://\(raw)")
    } else if let absolute = URL(string: raw), absolute.scheme != nil {
      absolute
    } else {
      URL(string: raw, relativeTo: baseURL)?.absoluteURL
    }
    // Drops `javascript:` and other schemes that have no business in a post.
    guard let url, let scheme = url.scheme?.lowercased(), Self.linkSchemes.contains(scheme) else { return nil }
    return url
  }
}
