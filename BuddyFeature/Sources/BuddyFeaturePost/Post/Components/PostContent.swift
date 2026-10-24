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

/// The optional AI summary plus the post's body: Tiptap rendered natively, HTML in a web view,
/// then any photos attached without being placed in the body.
struct PostContent: View {
  let summarisedContent: String?
  let content: PostBody?
  /// Attached photos the body doesn't show itself.
  var attachedImages: [URL] = []
  /// Identifies what the body shows (the original, or a translation), so swapping one for the
  /// other transitions rather than reflowing in place.
  var contentID: String = "original"
  /// Shows the body as a pulsing placeholder while it's being translated.
  var isTranslating: Bool = false
  let onLinkTapped: (URL) -> Void
  /// Scrolls the post to the image with this id while it's shown full screen.
  var onScrollToImage: (URL) -> Void = { _ in }

  @State private var gallery: ImageGallery?
  @State private var isPulsing = false
  @Namespace private var imageTransition

  var body: some View {
    if let summarisedContent {
      SummarisationView(text: summarisedContent)
        .padding(.bottom)
        .transition(.asymmetric(
          insertion: .offset(y: -10).combined(with: .opacity),
          removal: .opacity
        ))
    }

    contentView
      .id(contentID)
      .transition(.blurReplace)
      .redacted(reason: isTranslating ? .placeholder : [])
      .opacity(isPulsing ? 0.4 : 1)
      .allowsHitTesting(!isTranslating)
      .onChange(of: isTranslating, initial: true) { _, isTranslating in
        if isTranslating {
          withAnimation(.easeInOut(duration: 0.8).repeatForever()) { isPulsing = true }
        } else {
          withAnimation(.easeOut(duration: 0.2)) { isPulsing = false }
        }
      }
      .fullScreenCover(item: $gallery) { gallery in
        FullScreenImageViewer(
          gallery: gallery,
          transitionNamespace: imageTransition,
          onPageChange: onScrollToImage
        )
      }

    if !attachedImages.isEmpty {
      VStack(spacing: 12) {
        ForEach(attachedImages, id: \.self) { url in
          image(url)
        }
      }
    }
  }

  /// Every image in the post, inline ones first, for paging through full screen.
  private var galleryURLs: [URL] {
    var urls: [URL] = []
    if case .tiptap(let layout, _) = content {
      urls = layout.images.map(\.url)
    }
    return urls + attachedImages.filter { !urls.contains($0) }
  }

  /// An image that opens the post's images full screen, at itself.
  private func image(_ url: URL) -> some View {
    PostContentImage(url: url)
      .matchedTransitionSource(id: url, in: imageTransition)
      .id(url)
      .contentShape(.rect)
      .onTapGesture {
        gallery = ImageGallery(urls: galleryURLs, selected: url)
      }
      .accessibilityAddTraits(.isButton)
  }

  @ViewBuilder
  private var contentView: some View {
    switch content {
    case .tiptap(let layout, _):
      TiptapView(layout)
        .tiptapImage { image in
          self.image(image.url)
        }
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

/// An image loaded through Nuke, so it shares the app's image cache.
private struct PostContentImage: View {
  let url: URL

  var body: some View {
    LazyImage(url: url) { state in
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
