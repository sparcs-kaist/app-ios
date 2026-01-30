//
//  PostTranslationView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import SwiftUI
import BuddyDomain
import Factory

@preconcurrency
import Translation
import NaturalLanguage

struct PostTranslationView: View {
  let post: AraPost

  @Environment(\.dismiss) private var dismiss

  @State private var title: String = ""
  @State private var content: String = ""

  @State private var availableLanguages: [Locale.Language] = []
  @State private var selectedTarget: Locale.Language? = nil
  private let languageAvailability = LanguageAvailability()

  @State private var configuration: TranslationSession.Configuration?

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  @State private var isTranslating: Bool = true
  
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?

  init(post: AraPost) {
    self.post = post
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          Group {
            if isTranslating {
              Text(post.title ?? "")
                .font(.headline)
                .redacted(reason: isTranslating ? [.placeholder] : [])
            } else {
              Text(title)
                .font(.headline)
            }
          }
          .transition(.opacity)

          Divider()

          Group {
            if isTranslating {
              Text(content.isEmpty ? post.content ?? "" : content)
                .redacted(reason: isTranslating ? [.placeholder] : [])
            } else {
              Text(content)
            }
          }
          .transition(.opacity)
        }
        .padding()
        .animation(.spring, value: isTranslating)
      }
      .task {
        availableLanguages = await languageAvailability.supportedLanguages
        if let langCode = detectDominantLanguage(of: post.content?.convertFromHTML() ?? "") {
          availableLanguages = availableLanguages.filter { $0.languageCode?.identifier != langCode }
          if let targetLanguage = availableLanguages.first(where: { $0.languageCode?.identifier == (langCode == "ko" ? "en" : "ko") }) {
            selectedTarget = targetLanguage
          }
        }
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
          crashlyticsService?.recordException(error: error)
          errorMessage = "Failed to translate. Please try again."
          showErrorAlert = true
        }
      }
      .navigationTitle("Translate")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Error", isPresented: $showErrorAlert, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(errorMessage)
      })
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
  }

  private func displayName(for lang: Locale.Language) -> String {
    // Prefer base language code (e.g., "en", "ko")
    if let code = lang.languageCode?.identifier {
      return Locale.current.localizedString(forLanguageCode: code) ?? lang.minimalIdentifier
    }
    // Fallback: identifier (e.g., "en_US")
    return Locale.current.localizedString(forIdentifier: lang.minimalIdentifier) ?? lang.minimalIdentifier
  }

  private func detectDominantLanguage(of text: String) -> String? {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)

    if let language = recognizer.dominantLanguage {
      return language.rawValue
    }

    return nil
  }
}

#Preview {
  PostTranslationView(post: AraPost.mock)
}
