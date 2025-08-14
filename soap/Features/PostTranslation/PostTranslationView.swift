//
//  PostTranslationView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import SwiftUI

@preconcurrency
import Translation

struct PostTranslationView: View {
  let post: AraPost
  let convertedContent: String

  @Environment(\.dismiss) private var dismiss

  @State private var title: String = ""
  @State private var content: String = ""

  @State private var availableLanguages: [Locale.Language] = []
  @State private var selectedTarget: Locale.Language? = nil
  private let languageAvailability = LanguageAvailability()

  @State private var configuration: TranslationSession.Configuration?

  @State private var isTranslating: Bool = false

  init(post: AraPost, convertedContent: String) {
    self.post = post
    self.convertedContent = convertedContent
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          Text(selectedTarget == nil ? post.title ?? "" : title)
            .font(.headline)

          Divider()

          Text(selectedTarget == nil ? convertedContent : content)
        }
        .padding()
      }
      .task {
        availableLanguages = await languageAvailability.supportedLanguages
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Dismiss", systemImage: "xmark") {
            dismiss()
          }
        }
      }
      .safeAreaBar(edge: .bottom) {
        languageSelector
      }
      .translationTask(configuration) { session in
        isTranslating = true
        defer { isTranslating = false }

        do {
          async let translatedTitleTask = try await session.translate(post.title ?? "")
          async let translatedContentTask = try await session.translate(
            post.content?.convertFromHTML() ?? ""
          )

          let (translatedTitle, translatedContent) = try await (translatedTitleTask, translatedContentTask)

          await MainActor.run {
            title = translatedTitle.targetText
            content = translatedContent.targetText
          }
        } catch {
          // TODO: Handle error
        }
      }
    }
  }

  private func triggerTranslation() {
    guard configuration == nil else {
      configuration?.invalidate()
      configuration = TranslationSession.Configuration(source: nil, target: selectedTarget)

      return
    }

    configuration = TranslationSession.Configuration(source: nil, target: selectedTarget)
  }

  private var languageSelector: some View {
    Picker("", selection: $selectedTarget) {
      Text("Original")
        .tag(nil as Locale.Language?)

      ForEach(availableLanguages, id: \.minimalIdentifier) { language in
        Text("\(displayName(for: language))")
          .tag(language)
      }
    }
    .pickerStyle(.menu)
    .buttonStyle(.glass)
    .onChange(of: selectedTarget) {
      triggerTranslation()
    }
    .disabled(isTranslating)
    .overlay {
      if isTranslating {
        ProgressView()
          .controlSize(.small)
      }
    }
  }

  private func displayName(for lang: Locale.Language) -> String {
    // Prefer base language code (e.g., "en", "ko")
    if let code = lang.languageCode?.identifier {
      return Locale.current.localizedString(forLanguageCode: code) ?? lang.minimalIdentifier
    }
    // Fallback: identifier (e.g., "en_US")
    return Locale.current.localizedString(forIdentifier: lang.minimalIdentifier) ?? lang.minimalIdentifier
  }
}

#Preview {
  PostTranslationView(post: AraPost.mock, convertedContent: AraPost.mock.content?.convertFromHTML() ?? "")
}
