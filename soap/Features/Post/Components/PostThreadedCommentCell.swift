//
//  PostThreadedCommentCell.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import NukeUI

struct PostThreadedCommentCell: View {
  let comment: AraPostComment

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "arrow.turn.down.right")

      VStack(alignment: .leading, spacing: 8) {
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

          PostVoteButton(myVote: comment.myVote, votes: comment.upvotes - comment.downvotes, onDownvote: { }, onUpvote: { })
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
  PostThreadedCommentCell(comment: AraPostComment.mock)
    .padding()
}
