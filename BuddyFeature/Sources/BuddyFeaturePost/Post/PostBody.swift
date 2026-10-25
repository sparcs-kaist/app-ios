//
//  PostBody.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import BuddyDomain
import TiptapKit
import TiptapUI

/// How a post's `content` is presented. Boards post Tiptap JSON, rendered natively;
/// Portal Notice (and posts written before the editor change, or from this app) are HTML,
/// rendered in a local web view.
enum PostBody: Equatable, Sendable {
  case tiptap(TiptapLayout, plainText: String)
  /// `baseURL` resolves the HTML's relative image and link URLs.
  case html(String, baseURL: URL)

  /// Portal Notice is crawled from the KAIST portal, which leaves its image paths relative to it.
  private static let portalURL = URL(string: "https://portal.kaist.ac.kr/")!

  /// Parses and lays out `content`. Pure, so it can run off the main actor.
  static func make(from content: String, boardSlug: String?) -> PostBody {
    let baseURL = boardSlug == "portal-notice" ? portalURL : Constants.araPostURL
    // Malformed JSON falls back to HTML too, as the Ara web client does.
    guard let document = try? TiptapParser().parse(content) else {
      return .html(content, baseURL: baseURL)
    }
    return .tiptap(
      TiptapLayout(document: document, baseURL: baseURL),
      plainText: document.plainText
    )
  }

  /// About how many characters of text the post has, leaving out markup and whitespace.
  var textLength: Int {
    switch self {
    case .tiptap(_, let plainText):
      return plainText.count { !$0.isWhitespace }
    case .html(let html, _):
      // Counts what's outside tags; entities count a few characters each, near enough.
      var count = 0
      var isInTag = false
      for character in html {
        switch character {
        case "<": isInTag = true
        case ">": isInTag = false
        default: if !isInTag && !character.isWhitespace { count += 1 }
        }
      }
      return count
    }
  }
}

extension AraPost {
  /// The post's text without markup, for summarising and translation.
  @MainActor
  var contentPlainText: String {
    let content = content ?? ""
    if let document = try? TiptapParser().parse(content) {
      return document.plainText
    }
    // The HTML importer requires the main actor.
    return content.convertFromHTML()
  }
}

extension AraPost {
  /// Photos uploaded as attachments without being placed in the content (common on Real
  /// Estate), shown after it. An attachment counts as inline when the content refers to its file.
  var attachedImageURLs: [URL] {
    let images = (attachments ?? []).filter { $0.mimeType.hasPrefix("image/") && $0.file != nil }
    guard !images.isEmpty else { return [] }
    let content = content ?? ""
    // A Tiptap post names its photos in `src` attributes, and its JSON may escape `.` and `/`
    // (as this app writes them), so look in the parsed attributes rather than the raw string.
    let references = (try? TiptapParser().parse(content))
      .map { $0.content.flatMap(\.attributeStrings).joined(separator: "\n") } ?? content
    return images.compactMap { attachment in
      guard let url = attachment.file else { return nil }
      let names = [url.lastPathComponent, url.path(percentEncoded: true).split(separator: "/").last.map(String.init)]
      return names.contains { $0.map { !$0.isEmpty && references.contains($0) } ?? false } ? nil : url
    }
  }
}

private extension TiptapNode {
  /// Every string attribute in this node and below, such as image `src`s.
  var attributeStrings: [String] {
    attrs.values.compactMap(\.stringValue) + content.flatMap(\.attributeStrings)
  }
}
