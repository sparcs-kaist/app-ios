//
//  FeedCommentRow.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation
import SwiftUI
import Translation
import BuddyDomain
import BuddyFeatureShared

struct FeedCommentRow: View {
  @Binding var comment: FeedComment
  let isReply: Bool
  let onReply: (() -> Void)?

  @State private var viewModel: FeedCommentRowViewModelProtocol = FeedCommentRowViewModel()

  @State private var showFullContent: Bool = false
  @State private var showTranslateSheet: Bool = false
  @State private var safariSheetURL: URL? = nil
  @State private var isHiddenCommentExpanded: Bool = false

  private let authorTag = LocalizedString(["en": "Author", "ko": "작성자"])

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if isReply {
        Image(systemName: "arrow.turn.down.right")
          .padding(.top, 4)
      }
      VStack(alignment: .leading) {
        FeedCommentRowHeader(
          profileImageURL: comment.profileImageURL,
          authorName: comment.authorName,
          authorTagText: authorTag.localized(),
          isAuthor: comment.isAuthor,
          isMyComment: comment.isMyComment,
          isKaistIP: comment.isKaistIP,
          timeText: comment.createdAt.timeAgoDisplay,
          downvotes: comment.downvotes,
          showFullContent: showFullContent,
          isHiddenCommentExpanded: $isHiddenCommentExpanded,
          onTranslate: { showTranslateSheet = true },
          onDelete: { await viewModel.delete(comment: $comment) },
          onReport: { reason in await viewModel.reportComment(commentID: comment.id, reason: reason) }
        )

        if comment.downvotes < 15 || isHiddenCommentExpanded || showFullContent {
          FeedCommentContent(
            content: comment.content,
            isDeleted: comment.isDeleted,
            showFullContent: $showFullContent,
            onOpenURL: handleURL
          )
        }

        FeedCommentFooter(
          parentCommentID: comment.parentCommentID,
          replyCount: comment.replyCount,
          isDeleted: comment.isDeleted,
          myVote: comment.myVote == .up ? true : comment.myVote == .down ? false : nil,
          votes: comment.upvotes - comment.downvotes,
          onReply: onReply,
          onUpvote: { await viewModel.upvote(comment: $comment) },
          onDownvote: { await viewModel.downvote(comment: $comment) }
        )
      }
    }
    .translationPresentation(isPresented: $showTranslateSheet, text: comment.content)
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

#Preview {
  return
    LazyVStack {
      ForEach(.constant(FeedComment.mockList)) {
        FeedCommentRow(comment: $0, isReply: false, onReply: nil)
      }
    }
    .padding()
}
