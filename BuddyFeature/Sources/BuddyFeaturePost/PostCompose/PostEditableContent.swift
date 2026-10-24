//
//  PostEditableContent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import BuddyDomain
import TiptapKit

/// A post's body as a Tiptap document the editor can load, when the app can edit it.
enum PostEditableContent {
  /// The document to edit: the post's Tiptap JSON, or the simple HTML earlier versions of the
  /// app wrote (paragraphs and images). Other HTML, such as Portal Notice, returns `nil`:
  /// converting it would lose formatting the editor can't show.
  static func document(from content: String) -> TiptapDocument? {
    if let document = try? TiptapParser().parse(content) {
      return document
    }
    return documentFromAppHTML(content)
  }

  nonisolated(unsafe) private static let paragraphPattern = /<p>(.*?)<\/p>/.dotMatchesNewlines()
  nonisolated(unsafe) private static let imagePattern = /^\s*<img\b([^>]*)>\s*$/.ignoresCase()
  nonisolated(unsafe) private static let anchorPattern = /<a\b[^>]*>(.*?)<\/a>/.ignoresCase().dotMatchesNewlines()

  /// Parses `<p>text</p>` and `<p><img src="…" data-attachment="…"></p>` sequences, the only
  /// shapes the old composer produced. The server's linkifier may have wrapped URLs in anchors.
  private static func documentFromAppHTML(_ html: String) -> TiptapDocument? {
    let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return TiptapDocument(content: []) }

    var nodes: [TiptapNode] = []
    var consumed = trimmed.startIndex
    for match in trimmed.matches(of: paragraphPattern) {
      // Anything between paragraphs means it isn't the old composer's HTML.
      guard trimmed[consumed..<match.range.lowerBound].allSatisfy(\.isWhitespace) else { return nil }
      consumed = match.range.upperBound

      let inner = String(match.output.1)
      if let image = inner.firstMatch(of: imagePattern) {
        guard let node = imageNode(attributes: String(image.output.1)) else { return nil }
        nodes.append(TiptapNode(type: .paragraph, content: [node]))
        continue
      }
      let text = inner.replacing(anchorPattern) { String($0.output.1) }
      // Any other tag is formatting this parser doesn't know.
      guard !text.contains("<") else { return nil }
      let decoded = TiptapParser.decodingHTMLEntities(text)
      nodes.append(TiptapNode(type: .paragraph, content: decoded.isEmpty ? [] : [TiptapNode(type: .text, text: decoded)]))
    }
    guard trimmed[consumed...].allSatisfy(\.isWhitespace), !nodes.isEmpty else { return nil }
    return TiptapDocument(content: nodes)
  }

  private static func imageNode(attributes: String) -> TiptapNode? {
    func value(_ name: String) -> String? {
      guard let match = attributes.firstMatch(of: try! Regex("\(name)=\"([^\"]*)\"")),
            let captured = match.output[1].substring else { return nil }
      return TiptapParser.decodingHTMLEntities(String(captured))
    }
    guard let src = value("src") else { return nil }
    var attrs: [String: TiptapValue] = ["src": .string(src), "width": .number(Double(value("width") ?? "") ?? 500)]
    if let id = value("data-attachment") {
      attrs["data-attachment"] = .string(id)
    }
    return TiptapNode(type: .attachmentImage, attrs: attrs)
  }
}
