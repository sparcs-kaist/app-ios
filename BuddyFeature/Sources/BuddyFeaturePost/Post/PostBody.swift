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
/// left to the web view.
enum PostBody: Equatable, Sendable {
  case tiptap(TiptapLayout, plainText: String)
  case html

  /// Parses and lays out `content`. Pure, so it can run off the main actor.
  static func make(from content: String) -> PostBody {
    // Malformed JSON falls back to HTML too, as the Ara web client does.
    guard let document = try? TiptapParser().parse(content) else { return .html }
    return .tiptap(
      TiptapLayout(document: document, baseURL: Constants.araPostURL),
      plainText: document.plainText
    )
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
