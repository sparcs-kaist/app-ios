//
//  PostCommentsSection.swift
//  soap
//
//  Created by Codex on 13/02/2026.
//

import SwiftUI
import BuddyDomain

struct PostCommentsSection: View {
  @Binding var comments: [AraPostComment]

  let onReply: (AraPostComment) -> Void
  let onCommentDeleted: () -> Void
  let onEdit: (AraPostComment) -> Void
  let onUpvote: (Binding<AraPostComment>) async -> Void
  let onDownvote: (Binding<AraPostComment>) async -> Void
  let onReport: (Int, AraContentReportType) async throws -> Void
  let onDeleteComment: (Binding<AraPostComment>) async -> Void

  var body: some View {
    VStack(spacing: 16) {
      if comments.isEmpty {
        Divider()
        ContentUnavailableView(
          "No one has commented yet.",
          systemImage: "text.bubble",
          description: Text("Be the first one to share your thoughts.")
        )
        .scaleEffect(0.8)
      } else {
        ForEach($comments) { $comment in
          VStack(spacing: 12) {
            commentCell(comment: $comment, isThreaded: false)
              .id(comment.id)

            ForEach($comment.comments) { $thread in
              commentCell(comment: $thread, isThreaded: true)
                .id(thread.id)
            }
          }
        }
      }
    }
  }

  private func commentCell(comment: Binding<AraPostComment>, isThreaded: Bool) -> some View {
    PostCommentCell(
      comment: comment,
      isThreaded: isThreaded,
      onComment: {
        onReply(comment.wrappedValue)
      },
      onDelete: {
        onCommentDeleted()
      },
      onEdit: {
        onEdit(comment.wrappedValue)
      },
      onUpvote: {
        await onUpvote(comment)
      },
      onDownvote: {
        await onDownvote(comment)
      },
      onReport: { type in
        try await onReport(comment.wrappedValue.id, type)
      },
      onDeleteComment: {
        await onDeleteComment(comment)
      }
    )
  }
}
