//
//  FeedCommentsSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/08/2025.
//

import SwiftUI
import BuddyDomain

/// The comments list: loading placeholders, the loaded comment tree, or an
/// error state.
struct FeedCommentsSection: View {
  let state: FeedPostViewModel.ViewState
  @Binding var comments: [FeedComment]
  let commentCount: Int
  let onReply: (FeedComment) -> Void

  var body: some View {
    switch state {
    case .loading:
      VStack(alignment: .leading, spacing: 16) {
        Divider()
          .padding(.horizontal)

        Text("\(commentCount) comments", bundle: .module)
          .font(.headline)
          .padding(.horizontal)

        ForEach(FeedComment.mockList.prefix(4)) { comment in
          FeedCommentRow(comment: .constant(comment), isReply: false, onReply: nil)
            .padding(.horizontal)
            .redacted(reason: .placeholder)

          Divider()
            .padding(.horizontal)
        }
      }
    case .loaded:
      LazyVStack(alignment: .leading, spacing: 16) {
        Divider()
          .padding(.horizontal)

        Text("\(commentCount) comments", bundle: .module)
          .font(.headline)
          .padding(.horizontal)
          .contentTransition(.numericText(value: Double(commentCount)))
          .animation(.spring, value: commentCount)

        ForEach($comments) { $comment in
          FeedCommentRow(comment: $comment, isReply: false, onReply: {
            onReply(comment)
          })
          .padding(.horizontal)
          .id(comment.id)

          if !comment.replies.isEmpty {
            VStack(spacing: 12) {
              ForEach($comment.replies) { $reply in
                FeedCommentRow(comment: $reply, isReply: true, onReply: nil)
                  .padding(.horizontal)
                  .id(reply.id)
              }
            }
          }

          Divider()
            .padding(.horizontal)
        }
      }
      .animation(.spring, value: comments)
    case .error(let message):
      ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "text.bubble", description: Text(message))
        .scaleEffect(0.8)
    }
  }
}
