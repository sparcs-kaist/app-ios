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

  var body: some View {
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

        Button("more", systemImage: "ellipsis") { }
          .labelStyle(.iconOnly)
      }
      .font(.callout)

      Text(comment.content)
        .font(.callout)

      HStack {
        Spacer()

        PostCommentButton(commentCount: comment.comments?.count ?? 0)
          .fixedSize()

        PostVoteButton(
          myVote: comment.myVote,
          votes: comment.upvotes - comment.downvotes,
          onDownvote: {

          },
          onUpvote: {

          })
          .fixedSize()
      }
      .font(.caption)

      // Threads
//      if let threads = comment.comments {
//        ForEach(threads) { thread in
//          PostThreadedCommentCell(comment: thread)
//        }
//      }

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
  PostCommentCell(comment: AraPostComment.mock)
    .padding()
}
