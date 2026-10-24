//
//  PostTranslation.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import NaturalLanguage
import BuddyDomain
import TiptapKit
import TiptapUI
@preconcurrency import Translation

/// A post translated in place: the title and body, with the body's structure kept.
struct PostTranslation: Equatable {
  let title: String
  let layout: TiptapLayout
  let source: Locale.Language?
  let target: Locale.Language
}

enum PostTranslationState: Equatable {
  case original
  case translating(to: Locale.Language)
  case translated(PostTranslation)

  var target: Locale.Language? {
    switch self {
    case .original: nil
    case .translating(let target): target
    case .translated(let translation): translation.target
    }
  }
}

enum PostTranslator {
  /// The post's body as a document to translate block by block. HTML that isn't the app's own
  /// simple format is translated as plain paragraphs.
  @MainActor
  static func document(for post: AraPost) -> TiptapDocument {
    if let document = PostEditableContent.document(from: post.content ?? "") {
      return document
    }
    let paragraphs = post.contentPlainText
      .components(separatedBy: .newlines)
      .map { line in
        TiptapNode(type: .paragraph, content: line.isEmpty ? [] : [TiptapNode(type: .text, text: line)])
      }
    return TiptapDocument(content: paragraphs)
  }

  /// The language most of `text` is written in.
  static func dominantLanguage(of text: String) -> Locale.Language? {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    return recognizer.dominantLanguage.map { Locale.Language(identifier: $0.rawValue) }
  }

  /// Translates the title and each text block in one batch, and rebuilds the body around them.
  ///
  /// Each linked or styled phrase is also translated on its own, and its formatting is put back
  /// where that phrase appears in the block's translation. From iOS 26.4 blocks also go as
  /// attributed text; when the translator keeps their attribute runs, those are used instead.
  @MainActor
  static func translate(
    post: AraPost,
    document: TiptapDocument,
    using session: TranslationSession,
    source: Locale.Language?,
    target: Locale.Language
  ) async throws -> PostTranslation {
    let title = post.title ?? ""
    let attributed = document.attributedTextBlocks
    let blocks = attributed.blocks
    let isBlank = { (text: String) in text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var requests: [TranslationSession.Request] = []
    if !isBlank(title) {
      requests.append(.init(sourceText: title, clientIdentifier: "title"))
    }
    for (index, block) in blocks.enumerated() where !isBlank(String(block.characters)) {
      if #available(iOS 26.4, *) {
        requests.append(.init(sourceText: block, clientIdentifier: "b\(index)"))
      } else {
        requests.append(.init(sourceText: String(block.characters), clientIdentifier: "b\(index)"))
      }
      for (runIndex, run) in attributed.markedRuns(inBlock: index).enumerated() {
        requests.append(.init(sourceText: run.text, clientIdentifier: "r\(index)-\(runIndex)"))
      }
    }

    let responses = requests.isEmpty ? [] : try await session.translations(from: requests)
    var texts: [String: String] = [:]
    var attributedTexts: [String: AttributedString] = [:]
    for response in responses {
      guard let id = response.clientIdentifier else { continue }
      texts[id] = response.targetText
      if #available(iOS 26.4, *), let text = response.attributedTargetText {
        attributedTexts[id] = text
      }
    }

    let translatedBlocks = blocks.enumerated().map { index, block -> AttributedString in
      if let kept = attributedTexts["b\(index)"], TiptapAttributedTextBlocks.carriesMarks(kept) {
        return kept
      }
      guard let text = texts["b\(index)"] else { return block }
      let runs = attributed.markedRuns(inBlock: index).enumerated().map { runIndex, run in
        (run: run, translation: texts["r\(index)-\(runIndex)"] ?? run.text)
      }
      return TiptapAttributedTextBlocks.restoringMarks(runs, onto: text)
    }

    let translatedDocument = document.replacingTextBlocks(with: translatedBlocks, source: attributed)
    return PostTranslation(
      title: texts["title"] ?? title,
      layout: TiptapLayout(document: translatedDocument, baseURL: Constants.araPostURL),
      source: source,
      target: target
    )
  }

  /// Languages to offer as targets: one per language and script, with the region matching the
  /// device's where there's a choice, sorted by name. The post's own language is left out.
  static func targetLanguages(from supported: [Locale.Language], excluding source: Locale.Language?) -> [Locale.Language] {
    let region = Locale.current.region
    var chosen: [String: Locale.Language] = [:]
    for language in supported {
      let key = baseKey(of: language)
      guard key != source.map(baseKey(of:)) else { continue }
      if let existing = chosen[key], existing.region == region { continue }
      if chosen[key] == nil || language.region == region {
        chosen[key] = language
      }
    }
    return chosen.values.sorted { displayName(for: $0).localizedStandardCompare(displayName(for: $1)) == .orderedAscending }
  }

  /// "English", or "Chinese (Simplified)" where the script tells languages apart.
  static func displayName(for language: Locale.Language) -> String {
    let parts = baseKey(of: language).split(separator: "-")
    guard let code = parts.first.map(String.init) else { return language.minimalIdentifier }
    if code == "zh", parts.count > 1 {
      return Locale.current.localizedString(forIdentifier: "\(code)-\(parts[1])") ?? language.minimalIdentifier
    }
    return Locale.current.localizedString(forLanguageCode: code) ?? language.minimalIdentifier
  }

  /// Language and script, e.g. "en-Latn" for both en-US and en-GB.
  private static func baseKey(of language: Locale.Language) -> String {
    language.maximalIdentifier.split(separator: "-").prefix(2).joined(separator: "-")
  }
}
