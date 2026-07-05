//
//  FeedPostRow.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import BuddyPreviewSupport

struct FeedPostRow: View {
  @Binding var post: FeedPost
  let onPostDeleted: ((String) -> Void)?
  let onComment: (() -> Void)?
  @State var showFullContent: Bool = false

  @State private var viewModel: FeedPostRowViewModelProtocol = FeedPostRowViewModel()

  @State private var showTranslateSheet: Bool = false
  @State private var safariSheetURL: URL? = nil
  @State private var isHiddenPostExpanded: Bool = false

  private var isFeedContext: Bool { onPostDeleted != nil }

  var body: some View {
    VStack(alignment: .leading) {
      FeedPostRowHeader(
        profileImageURL: post.profileImageURL,
        authorName: post.authorName,
        isKaistIP: post.isKaistIP,
        timeText: isFeedContext ? post.createdAt.timeAgoDisplay : post.createdAt.relativeTimeString,
        downvotes: post.downvotes,
        isAuthor: post.isAuthor,
        isFeedContext: isFeedContext,
        showFullContent: showFullContent,
        isHiddenPostExpanded: $isHiddenPostExpanded,
        onTranslate: { showTranslateSheet = true },
        onReport: { reason in await viewModel.reportPost(postID: post.id, reason: reason) },
        onDelete: { onPostDeleted?(post.id) }
      )

      if post.downvotes < 15 || isHiddenPostExpanded || showFullContent {
        FeedPostContent(
          content: post.content,
          images: post.images,
          showFullContent: $showFullContent,
          onOpenURL: handleURL
        )
      }

      FeedPostFooter(
        myVote: post.myVote == .up ? true : post.myVote == .down ? false : nil,
        votes: post.upvotes - post.downvotes,
        commentCount: post.commentCount,
        canComment: onComment != nil,
        onUpvote: { await viewModel.upvote(post: $post) },
        onDownvote: { await viewModel.downvote(post: $post) },
        onComment: { onComment?() }
      )
    }
    .translationPresentation(
      isPresented: $showTranslateSheet,
      text: post.content
    )
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
      }
    )
    .sheet(item: $safariSheetURL) { url in
      SafariViewWrapper(url: url)
    }
  }

  private func handleURL(_ url: URL) -> OpenURLAction.Result {
    if let deepLink = DeepLink(url: url) {
      NotificationCenter.default.post(name: .buddyInternalDeepLink, object: deepLink)
      return .handled
    }

    safariSheetURL = url
    return .handled
  }
}

// MARK: - Previews

#Preview("With Actions") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: { _ in }, onComment: { })
    .environment(spoilerContents)
}

#Preview("Without Actions") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: nil, onComment: nil)
    .environment(spoilerContents)
}

#Preview("Anonymous") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[4]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}

#Preview("Long Content") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[6]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}

#Preview("Multiple Images") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[5]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}

#Preview("URL Content") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[8]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}
