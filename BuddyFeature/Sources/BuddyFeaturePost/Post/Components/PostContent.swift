//
//  PostContent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI
import NukeUI
import TiptapUI
import BuddyFeatureShared

/// The optional AI summary plus the post's body: Tiptap rendered natively, HTML in a web view.
struct PostContent: View {
  let summarisedContent: String?
  let content: PostBody?
  let onLinkTapped: (URL) -> Void

  var body: some View {
    if let summarisedContent {
      SummarisationView(text: summarisedContent)
        .padding(.bottom)
        .transition(.asymmetric(
          insertion: .offset(y: -10).combined(with: .opacity),
          removal: .opacity
        ))
    }

    switch content {
    case .tiptap(let layout, _):
      TiptapView(layout)
        .tiptapImage { PostContentImage(image: $0) }
        .environment(\.openURL, OpenURLAction { url in
          // The in-app Safari sheet only takes web URLs; mailto: and tel: go to the system.
          guard ["http", "https"].contains(url.scheme?.lowercased()) else { return .systemAction }
          onLinkTapped(url)
          return .handled
        })
    case .html(let html, let baseURL):
      PostHTMLContent(html: html, baseURL: baseURL, onLinkTapped: onLinkTapped)
    case nil:
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding()
    }
  }
}

/// An image block loaded through Nuke, so it shares the app's image cache.
private struct PostContentImage: View {
  let image: TiptapImage

  var body: some View {
    LazyImage(url: image.url) { state in
      if let loaded = state.image {
        loaded
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(.fill.tertiary)
          .aspectRatio(4 / 3, contentMode: .fit)
          .overlay {
            if state.error != nil {
              Image(systemName: "photo.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            } else {
              ProgressView()
            }
          }
      }
    }
    .clipShape(.rect(cornerRadius: 8))
  }
}

/// HTML content (Portal Notice and older posts), rendered locally.
private struct PostHTMLContent: View {
  let html: String
  let baseURL: URL
  let onLinkTapped: (URL) -> Void

  @State private var height: CGFloat = .zero

  var body: some View {
    DynamicHeightWebView(
      html: html,
      baseURL: baseURL,
      height: $height,
      onLinkTapped: onLinkTapped
    )
    .frame(height: max(1, height))
    .overlay {
      if height == .zero {
        ProgressView()
          .padding()
      }
    }
  }
}
