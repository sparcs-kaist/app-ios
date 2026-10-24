//
//  PostToolsTip.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 19/10/2026.
//

import Foundation
import NaturalLanguage
import SwiftUI
import TipKit

/// Under a post's header, pointing at its More menu, which holds Translate and Summarise, once a
/// few posts have been read and this one is long or in another language.
struct PostToolsTip: Tip {
  static let postOpened = Tips.Event(id: "post.opened")

  var title: Text { Text("Translate or Summarise", bundle: .module) }
  var message: Text? { Text("Translate a post, or summarise a long one, from the \(Image(systemName: "ellipsis.circle")) menu.", bundle: .module) }
  var image: Image? { Image(systemName: "translate") }
  var rules: [Rule] {
    [#Rule(Self.postOpened) { $0.donations.count >= 3 }]
  }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }

  /// Whether a post's text (HTML or plain) is long, or in a language other than the app's, so the
  /// menu would help.
  static func isWorthShowing(for content: String) -> Bool {
    let text = content.replacing(/<[^>]+>/, with: " ")
    if text.count >= 500 { return true }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    guard let language = recognizer.dominantLanguage?.rawValue,
          let appLanguage = Locale.current.language.languageCode?.identifier else { return false }
    return Locale.Language(identifier: language).languageCode?.identifier != appLanguage
  }
}
