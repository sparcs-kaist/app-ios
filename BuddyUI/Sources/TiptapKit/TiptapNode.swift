import Foundation

/// A node of a Tiptap (ProseMirror) JSON document.
///
/// The model is deliberately schema-agnostic: node and mark types are open string
/// wrappers, so a document using an extension this module doesn't know about still
/// decodes, and renderers can fall back to the node's children.
public struct TiptapNode: Sendable, Hashable {
  public var type: TiptapNodeType
  public var attrs: [String: TiptapValue]
  public var content: [TiptapNode]
  public var marks: [TiptapMark]
  /// Set only on `text` nodes.
  public var text: String?

  public init(
    type: TiptapNodeType,
    attrs: [String: TiptapValue] = [:],
    content: [TiptapNode] = [],
    marks: [TiptapMark] = [],
    text: String? = nil
  ) {
    self.type = type
    self.attrs = attrs
    self.content = content
    self.marks = marks
    self.text = text
  }

  public subscript(attribute name: String) -> TiptapValue? {
    attrs[name]
  }
}

extension TiptapNode: Decodable {
  private enum CodingKeys: String, CodingKey {
    case type, attrs, content, marks, text
  }

  // Every key is optional: editors omit empty `content`/`marks`/`attrs`, and a
  // malformed attribute shouldn't cost the whole document.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = TiptapNodeType(rawValue: try container.decodeIfPresent(String.self, forKey: .type) ?? "")
    attrs = (try? container.decodeIfPresent([String: TiptapValue].self, forKey: .attrs)) ?? [:]
    content = try container.decodeIfPresent([TiptapNode].self, forKey: .content) ?? []
    marks = (try? container.decodeIfPresent([TiptapMark].self, forKey: .marks)) ?? []
    text = try container.decodeIfPresent(String.self, forKey: .text)
  }
}

/// An inline formatting mark (bold, link, colour, …) applied to a `text` node.
public struct TiptapMark: Sendable, Hashable, Decodable {
  public var type: TiptapMarkType
  public var attrs: [String: TiptapValue]

  public init(type: TiptapMarkType, attrs: [String: TiptapValue] = [:]) {
    self.type = type
    self.attrs = attrs
  }

  private enum CodingKeys: String, CodingKey {
    case type, attrs
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = TiptapMarkType(rawValue: try container.decode(String.self, forKey: .type))
    attrs = (try? container.decodeIfPresent([String: TiptapValue].self, forKey: .attrs)) ?? [:]
  }

  public subscript(attribute name: String) -> TiptapValue? {
    attrs[name]
  }
}

public struct TiptapNodeType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  // StarterKit
  public static let doc: Self = "doc"
  public static let paragraph: Self = "paragraph"
  public static let text: Self = "text"
  public static let heading: Self = "heading"
  public static let blockquote: Self = "blockquote"
  public static let bulletList: Self = "bulletList"
  public static let orderedList: Self = "orderedList"
  public static let listItem: Self = "listItem"
  public static let codeBlock: Self = "codeBlock"
  public static let hardBreak: Self = "hardBreak"
  public static let horizontalRule: Self = "horizontalRule"
  public static let image: Self = "image"

  // Ara extensions
  public static let attachmentImage: Self = "attachmentImage"
  public static let linkBookmark: Self = "linkBookmark"

  /// Nodes whose children are inline content rather than blocks.
  public var isTextblock: Bool {
    self == .paragraph || self == .heading || self == .codeBlock
  }
}

public struct TiptapMarkType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public static let bold: Self = "bold"
  public static let italic: Self = "italic"
  public static let underline: Self = "underline"
  public static let strike: Self = "strike"
  public static let code: Self = "code"
  public static let link: Self = "link"
  public static let textStyle: Self = "textStyle"
  public static let highlight: Self = "highlight"
}
