import Foundation

/// A parsed Tiptap document: the top-level block nodes of its `doc` root.
public struct TiptapDocument: Sendable, Hashable {
  public var content: [TiptapNode]

  public init(content: [TiptapNode]) {
    self.content = content
  }

  public var isEmpty: Bool {
    content.isEmpty
  }
}

public enum TiptapParseError: Error, Equatable {
  /// The string isn't a JSON object, so it is most likely HTML or plain text.
  case notJSON
  /// The string looked like JSON but couldn't be decoded, even after repair.
  case malformed
}

/// Decodes Tiptap JSON strings into a ``TiptapDocument``.
///
/// Besides well-formed documents, the parser can undo the damage done by servers that
/// pass the JSON string through an HTML sanitiser (such as bleach, used by Ara):
/// URLs get wrapped in `<a href="…">` tags, which breaks the JSON quoting, and `&`, `<`
/// and `>` inside string values are escaped as HTML entities.
public struct TiptapParser: Sendable {
  public struct Options: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Unwraps `<a …>url</a>` tags injected into JSON string values by a linkifier,
    /// retried only when the raw string fails to decode.
    public static let repairLinkifiedURLs = Options(rawValue: 1 << 0)
    /// Decodes HTML entities in text and attribute strings.
    public static let decodeHTMLEntities = Options(rawValue: 1 << 1)

    public static let strict: Options = []
    public static let lenient: Options = [.repairLinkifiedURLs, .decodeHTMLEntities]
  }

  public var options: Options

  public init(options: Options = .lenient) {
    self.options = options
  }

  /// Decodes `&amp;`, `&lt;`, `&#54620;` and the like, as an HTML sanitiser leaves them.
  public static func decodingHTMLEntities(_ string: String) -> String {
    HTMLEntities.decode(string)
  }

  /// Whether `string` should be treated as Tiptap JSON rather than HTML — the same
  /// check the Ara server and web client make.
  public static func isTiptapJSON(_ string: String) -> Bool {
    string.first(where: { !$0.isWhitespace }) == "{"
  }

  public func parse(_ string: String) throws(TiptapParseError) -> TiptapDocument {
    guard Self.isTiptapJSON(string) else { throw .notJSON }

    var root = Self.decodeRoot(string)
    if root == nil, options.contains(.repairLinkifiedURLs) {
      let repaired = Self.unwrapAnchors(in: string)
      root = Self.decodeRoot(repaired) ?? Self.decodeRoot(Self.removeTrailingCommas(in: repaired))
    }
    guard var nodes = root else { throw .malformed }

    if options.contains(.decodeHTMLEntities) {
      nodes = nodes.map { $0.decodingHTMLEntities() }
    }
    return TiptapDocument(content: nodes)
  }

  // MARK: - Decoding

  private struct WrappedDocument: Decodable {
    let content: TiptapNode
  }

  /// Returns the top-level blocks, accepting both a bare `doc` and one wrapped as
  /// `{"content": {"type": "doc", …}}`.
  private static func decodeRoot(_ string: String) -> [TiptapNode]? {
    let data = Data(string.utf8)
    let decoder = JSONDecoder()
    if let node = try? decoder.decode(TiptapNode.self, from: data) {
      switch node.type {
      case .doc, "": return node.content
      default: return [node]
      }
    }
    if let wrapped = try? decoder.decode(WrappedDocument.self, from: data) {
      return wrapped.content.type == .doc ? wrapped.content.content : [wrapped.content]
    }
    return nil
  }

  // MARK: - Repair

  nonisolated(unsafe) private static let anchorPattern = /<a\b[^>]*>(.*?)<\/a>/
    .ignoresCase()
    .dotMatchesNewlines()
  nonisolated(unsafe) private static let trailingCommaPattern = /,(\s*[}\]])/

  /// A linkifier turns `"href":"https://x"` into `"href":"<a href="https://x" rel="nofollow">https://x</a>"`.
  /// The anchor's text is the original URL, so keeping only that restores the JSON.
  static func unwrapAnchors(in string: String) -> String {
    guard string.range(of: "<a", options: .caseInsensitive) != nil else { return string }
    return string.replacing(anchorPattern) { String($0.output.1) }
  }

  static func removeTrailingCommas(in string: String) -> String {
    string.replacing(trailingCommaPattern) { String($0.output.1) }
  }
}

private extension TiptapNode {
  func decodingHTMLEntities() -> TiptapNode {
    var node = self
    node.text = text.map(HTMLEntities.decode)
    if !attrs.isEmpty {
      node.attrs = attrs.mapValues(\.decodingHTMLEntities)
    }
    if !marks.isEmpty {
      node.marks = marks.map { mark in
        var mark = mark
        mark.attrs = mark.attrs.mapValues(\.decodingHTMLEntities)
        return mark
      }
    }
    if !content.isEmpty {
      node.content = content.map { $0.decodingHTMLEntities() }
    }
    return node
  }
}

private extension TiptapValue {
  var decodingHTMLEntities: TiptapValue {
    if case .string(let value) = self {
      return .string(HTMLEntities.decode(value))
    }
    return self
  }
}
