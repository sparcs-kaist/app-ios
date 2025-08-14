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

  @State private var title: String = ""
  @State private var content: String = ""

  @State private var configuration: TranslationSession.Configuration?
  @State private var translateToEnglish: Bool // translate to korean if it's false
  @Namespace private var namespace

  init(post: AraPost) {
    self.post = post

    let languageCode = Locale.current.language.languageCode?.identifier ?? "ko"
    translateToEnglish = languageCode != "ko"
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)

        Divider()

        Text(content)
      }
      .padding()
    }
    .safeAreaBar(edge: .bottom) {
      languageSelector
    }
    .translationTask(configuration) { session in
      do {
        async let translatedTitleTask = try await session.translate(post.title ?? "")
        async let translatedContentTask = try await session.translate(post.content ?? "")

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

  private func triggerTranslation() {
    guard configuration == nil else {
      configuration?.invalidate()
      return
    }

    let target = translateToEnglish ? "en" : "ko"
    configuration = TranslationSession
      .Configuration(source: nil, target: Locale.Language(identifier: target))
  }

  private var languageSelector: some View {
    GlassEffectContainer {
      HStack {
        if translateToEnglish {
          languageCapsule("Korean")
            .matchedGeometryEffect(id: "Korean", in: namespace)
        } else {
          languageCapsule("English")
            .matchedGeometryEffect(id: "English", in: namespace)
        }

        Button("Change", systemImage: "arrow.left.and.right") {
          withAnimation(.spring) {
            translateToEnglish.toggle()
            triggerTranslation()
          }
        }
        .labelStyle(.iconOnly)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .padding(12)
        .glassEffect(.clear.interactive(), in: .circle)

        if translateToEnglish {
          languageCapsule("English")
            .matchedGeometryEffect(id: "English", in: namespace)
        } else {
          languageCapsule("Korean")
            .matchedGeometryEffect(id: "Korean", in: namespace)
        }
      }
    }
  }

  private func languageCapsule(_ language: String) -> some View {
    Text(language)
      .textCase(.uppercase)
      .fontDesign(.rounded)
      .fontWeight(.semibold)
      .frame(width: 80)
      .padding(12)
      .glassEffect(.clear)
  }
}

#Preview {
  PostTranslationView(post: AraPost.mock)
}
