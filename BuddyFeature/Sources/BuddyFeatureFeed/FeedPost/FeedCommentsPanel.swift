//
//  FeedCommentsPanel.swift
//  BuddyFeature
//
//  Created by Jungwoo Ha on 04/10/2026.
//

import SwiftUI
import Factory
import BuddyDomain
import BuddyPreviewSupport
import FirebaseAnalytics

/// A post's comments shown in a column beside the feed on wide layouts, so
/// reading and writing comments doesn't leave the feed.
struct FeedCommentsPanel: View {
  @Binding var post: FeedPost
  let onClose: () -> Void

  @FocusState private var isWritingCommentFocusState: Bool

  /// The comment to pin to the top while a reply to it is being written.
  private var replyScrollTargetID: String? {
    isWritingCommentFocusState ? viewModel.targetComment?.id : nil
  }

  @State private var viewModel: FeedPostViewModelProtocol

  init(
    post: Binding<FeedPost>,
    viewModel: FeedPostViewModelProtocol = FeedPostViewModel(),
    onClose: @escaping () -> Void
  ) {
    self._post = post
    self._viewModel = State(initialValue: viewModel)
    self.onClose = onClose
  }

  var body: some View {
    VStack(spacing: 0) {
      header

      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            FeedCommentsSection(
              state: viewModel.state,
              comments: $viewModel.comments,
              commentCount: post.commentCount,
              showsLeadingDivider: false,
              onReply: { comment in
                viewModel.targetComment = comment
                isWritingCommentFocusState = true
              }
            )

            if replyScrollTargetID != nil {
              Color.clear
                .containerRelativeFrame(.vertical)
            }
          }
        }
        .onChange(of: replyScrollTargetID) { _, id in
          guard let id else { return }
          Task { @MainActor in
            withAnimation(.spring) {
              proxy.scrollTo(id, anchor: .top)
            }
          }
        }
        .task(id: post.id) {
          await viewModel.fetchComments(postID: post.id, initial: true)
          await viewModel.fetchFeedUser()
        }
        .refreshable {
          await viewModel.fetchComments(postID: post.id, initial: false)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaBar(edge: .bottom) {
          FeedCommentInputBar(
            text: $viewModel.text,
            isAnonymous: $viewModel.isAnonymous,
            targetComment: $viewModel.targetComment,
            isFocused: $isWritingCommentFocusState,
            isSubmitting: viewModel.isSubmittingComment,
            onSubmit: {
              Task {
                if let uploadedComment = await viewModel.submitComment(postID: post.id, replyingTo: viewModel.targetComment) {
                  post.commentCount += 1
                  viewModel.targetComment = nil
                  isWritingCommentFocusState = false

                  withAnimation(.spring) {
                    proxy.scrollTo(uploadedComment.id, anchor: .center)
                  }
                }
              }
            }
          )
        }
      }
      .alert(
        viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
        isPresented: $viewModel.isAlertPresented,
        actions: {
          Button(String(localized: "Okay", bundle: .module), role: .close) { }
        }, message: {
          Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
        }
      )
    }
    .analyticsScreen(
      name: "Feed Comments Panel",
      class: String(describing: Self.self),
      extraParameters: [
        "is_author": post.isAuthor,
        "has_comments": post.commentCount > 0
      ]
    )
  }

  private var header: some View {
    HStack {
      Text("Comments", bundle: .module)
        .font(.headline)

      Spacer()

      Button(String(localized: "Close", bundle: .module), systemImage: "xmark", action: onClose)
        .labelStyle(.iconOnly)
        .padding(8)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}

// MARK: - Previews

#Preview("Comments Panel") {
  let _ = Container.setupFeedPreview()
  FeedCommentsPanel(post: .constant(FeedPost.mockList[6]), onClose: { })
}
