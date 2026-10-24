//
//  PostTranslationBanner.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI

/// Above a post translated in place: which languages, and the way back to the original.
struct PostTranslationBanner: View {
  let state: PostTranslationState
  let onShowOriginal: () -> Void

  var body: some View {
    switch state {
    case .original:
      EmptyView()
    case .translating(let target):
      HStack(spacing: 8) {
        ProgressView()
          .controlSize(.small)
        Text("Translating to \(PostTranslator.displayName(for: target))…", bundle: .module)
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
      .transition(.opacity)
    case .translated(let translation):
      HStack(spacing: 6) {
        Image(systemName: "translate")
        Text(description(of: translation))
          .lineLimit(1)
        Spacer(minLength: 8)
        Button(String(localized: "Show Original", bundle: .module), action: onShowOriginal)
          .fontWeight(.medium)
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
      .transition(.opacity)
    }
  }

  private func description(of translation: PostTranslation) -> String {
    let target = PostTranslator.displayName(for: translation.target)
    if let source = translation.source {
      return String(localized: "Translated from \(PostTranslator.displayName(for: source)) to \(target)", bundle: .module)
    }
    return String(localized: "Translated to \(target)", bundle: .module)
  }
}
