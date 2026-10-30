//
//  FeedPostContent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// Post body text (with expand affordance) and any attached images.
struct FeedPostContent: View {
  let postID: String
  let content: String
  let images: [FeedImage]
  @Binding var showFullContent: Bool
  let onOpenURL: (URL) -> OpenURLAction.Result

  @State private var canBeExpanded: Bool = false

  /// Posts already found to run past five lines. The feed's lazy stack rebuilds
  /// rows as they scroll back in, and without this the "more" button would
  /// appear a frame late and shift everything below it.
  private static var expandablePostIDs: Set<String> = []

  private var showsMoreButton: Bool {
    canBeExpanded || Self.expandablePostIDs.contains(postID)
  }

  var body: some View {
    Text(content.toDetectedAttributedString())
      .textSelection(.enabled)
      .padding(.horizontal)
      .lineLimit(showFullContent ? nil : 5)
      .background {
        ViewThatFits(in: .vertical) {
          Text(content)
            .hidden()
          Color.clear.onAppear {
            canBeExpanded = true
            Self.expandablePostIDs.insert(postID)
          }
        }
      }
      .environment(\.openURL, OpenURLAction(handler: onOpenURL))
    if showsMoreButton && !showFullContent {
      Button(String(localized: "more", bundle: .module)) {
        withAnimation {
          showFullContent = true
        }
      }
      .padding(.horizontal)
      .foregroundStyle(.secondary)
    }
    if !images.isEmpty {
      PostImagesStrip(images: images)
    }
  }
}
