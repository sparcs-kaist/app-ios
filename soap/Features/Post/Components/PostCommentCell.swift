//
//  PostCommentCell.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import NukeUI

struct PostCommentCell: View {
  let comment: AraPostComment
  let isThreaded: Bool
  let onDownvote: (() -> Void)
  let onUpvote: (() -> Void)
  let onComment: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if isThreaded {
        Image(systemName: "arrow.turn.down.right")
      }

      VStack(alignment: .leading, spacing: 8) {
        Divider()

        HStack {
          profilePicture

          Text(comment.author.profile.nickname)
            .fontWeight(.medium)

          Text(comment.createdAt.relativeTimeString)
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()

          Menu {
            if comment.isMine == false {
              // show report menu
              Menu("Report", systemImage: "exclamationmark.triangle.fill") {
                Button("Hate Speech") { }
                Button("Unauthorized Sales Post") { }
                Button("Spam") { }
                Button("False Information") { }
                Button("Defamation") { }
                Button("Other") { }
              }
            } else if comment.isMine == true {
              // show edit button
              Button("Edit", systemImage: "square.and.pencil") { }
            }

            Divider()

            Button("Translate", systemImage: "translate") { }
            Button("Summarise", systemImage: "text.append") { }

            if comment.isMine == true {
              Divider()

              Button("Delete", systemImage: "trash", role: .destructive) { }
            }
          } label: {
            Label("More", systemImage: "ellipsis")
              .padding(8)
              .contentShape(.rect)
          }
          .labelStyle(.iconOnly)
        }
        .font(.callout)

        Text(comment.content ?? "This comment has been deleted.")
          .foregroundStyle(comment.content != nil ? .primary : .secondary)
          .font(.callout)

        HStack {
          Spacer()

          if !isThreaded {
            PostCommentButton(commentCount: comment.comments?.count ?? 0) {
              onComment?()
            }
            .fixedSize()
          }

          PostVoteButton(
            myVote: comment.myVote,
            votes: comment.upvotes - comment.downvotes,
            onDownvote: {
              onDownvote()
            },
            onUpvote: {
              onUpvote()
            }
          )
          .disabled(comment.isMine ?? false)
          .fixedSize()
        }
        .font(.caption)
      }
    }
  }

  @ViewBuilder
  var profilePicture: some View {
    if let url = comment.author.profile.profilePictureURL {
      LazyImage(url: url) { state in
        if let image = state.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Circle()
            .fill(Color.secondarySystemBackground)
        }
      }
      .frame(width: 21, height: 21)
      .clipShape(.circle)
    } else {
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: 21, height: 21)
    }
  }
}


#Preview {
  PostCommentCell(
    comment: AraPostComment.mock,
    isThreaded: false,
    onDownvote: {},
    onUpvote: {},
    onComment: nil)
    .padding()
  PostCommentCell(
    comment: AraPostComment.mock,
    isThreaded: true,
    onDownvote: {},
    onUpvote: {},
    onComment: nil)
  .padding()
}
