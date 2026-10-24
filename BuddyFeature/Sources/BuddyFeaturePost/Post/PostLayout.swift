//
//  PostLayout.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import TipKit
import BuddyDomain
import BuddyFeatureShared

/// A scrolling column: the whole post on a phone, or one pane beside the other.
struct PostColumn<Content: View>: View {
  let summarisedContent: String?
  let translationState: PostTranslationState
  @ViewBuilder let content: Content

  var body: some View {
    ScrollView {
      Group {
        content
      }
      .padding()
      .contentWidth()
      .animation(.spring(), value: summarisedContent)
      // The title and body settle into their translation, or back to the original.
      .animation(.spring(duration: 0.5, bounce: 0.15), value: translationState)
    }
  }
}

/// Floors for the two panes. Each fits half of a folded iPhone Duo (455 points), so folding
/// puts one pane on each side of the hinge rather than dropping the arrangement.
enum PostPaneWidth {
  static let post: CGFloat = 380
  static let comments: CGFloat = 320
}

/// The post on the left and its comments on the right.
struct PostPanes<Post: View, Comments: View>: View {
  @ViewBuilder let post: Post
  @ViewBuilder let comments: Comments

  @Environment(\.displayScale) private var displayScale

  var body: some View {
    if #available(iOS 27.1, *) {
      ArrangementView {
        post
          .splitArrangementLayoutSize(minWidth: PostPaneWidth.post, idealWidth: 560)
      } secondary: {
        comments
          // A rule down the pane's leading edge, top to bottom, between the post and its comments.
          .overlay(alignment: .leading) {
            Rectangle()
              .fill(.separator)
              .frame(width: 1 / displayScale)
              .ignoresSafeArea(edges: .vertical)
          }
          .splitArrangementLayoutSize(minWidth: PostPaneWidth.comments)
      }
      .arrangementViewStyle(.split.axes(.horizontal))
    } else {
      HStack(spacing: 0) {
        post
          .frame(minWidth: PostPaneWidth.post, maxWidth: .infinity)
          .layoutPriority(1)
        Divider()
        comments
          .frame(minWidth: PostPaneWidth.comments, maxWidth: 420)
      }
    }
  }
}

/// Title, body and votes.
struct PostSection: View {
  let viewModel: any PostViewModelProtocol
  let title: AttributedString
  let content: PostBody?
  let summarisedContent: String?
  let isTranslating: Bool
  let showsToolsTip: Bool
  let onAuthorTapped: () -> Void
  let onLinkTapped: (URL) -> Void
  let onScrollToImage: (URL) -> Void
  let onCommentTapped: () -> Void

  var body: some View {
    PostHeader(
      title: title,
      createdAtText: viewModel.post.createdAt.formattedString,
      views: viewModel.post.views,
      authorProfileURL: viewModel.post.author.profile.profilePictureURL,
      authorNickname: viewModel.post.author.profile.nickname,
      isAnonymous: viewModel.post.isAnonymous,
      marketListing: viewModel.post.board?.isMarket == true ? viewModel.post.marketListing : nil,
      onAuthorTapped: onAuthorTapped
    )

    if showsToolsTip {
      TipView(PostToolsTip())
    }

    PostTranslationBanner(state: viewModel.translationState) {
      viewModel.showOriginal()
    }

    PostContent(
      summarisedContent: summarisedContent,
      content: content,
      attachedImages: viewModel.post.attachedImageURLs,
      contentID: viewModel.translationState.target?.minimalIdentifier ?? "original",
      isTranslating: isTranslating,
      onLinkTapped: onLinkTapped,
      onScrollToImage: onScrollToImage
    )

    PostFooter(
      myVote: viewModel.myVote,
      votes: viewModel.upvotes - viewModel.downvotes,
      isMine: viewModel.post.isMine,
      commentCount: viewModel.commentCount,
      isBookmarked: viewModel.myScrap,
      shareURL: Constants.araPostURL.appending(path: String(viewModel.post.id)),
      onUpvote: { await viewModel.upvote() },
      onDownvote: { await viewModel.downvote() },
      onToggleBookmark: { await viewModel.toggleBookmark() },
      onCommentTapped: onCommentTapped
    )
  }
}

/// The comments under a post, or in their own pane.
struct PostComments: View {
  let viewModel: any PostViewModelProtocol
  @Binding var comments: [AraPostComment]
  var showsTopDivider = true
  let onReply: (AraPostComment) -> Void
  let onEdit: (AraPostComment) -> Void
  let onCommentDeleted: () -> Void

  var body: some View {
    PostCommentsSection(
      comments: $comments,
      onReply: onReply,
      onCommentDeleted: onCommentDeleted,
      onEdit: onEdit,
      onUpvote: { target in
        await viewModel.upvoteComment(comment: target)
      },
      onDownvote: { target in
        await viewModel.downvoteComment(comment: target)
      },
      onReport: { commentID, type in
        try await viewModel.reportComment(commentID: commentID, type: type)
      },
      onDeleteComment: { target in
        await viewModel.deleteComment(comment: target)
      },
      showsTopDivider: showsTopDivider
    )
    .padding(.top, 4)
    .animation(.spring, value: comments.map(\.id))
  }
}

/// Keeps the navigation bar from minimizing on scroll. Side by side, the bar would follow
/// whichever pane scrolled, so scrolling the comments would shrink the bar over the post.
struct PinnedNavigationBar: ViewModifier {
  let isPinned: Bool

  func body(content: Content) -> some View {
    if #available(iOS 27.0, *), isPinned {
      content.toolbarMinimizationBehavior(.never, for: .navigationBar)
    } else {
      content
    }
  }
}
