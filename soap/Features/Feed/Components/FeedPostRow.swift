//
//  FeedPostRow.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI

struct FeedPostRow: View {
  @Binding var post: FeedPost

  var body: some View {
    Group {
      VStack(alignment: .leading) {
        // header
        header

        // content
        content

        // footer
        footer
      }
    }
  }

  @ViewBuilder
  var profileImage: some View {
    if let url = post.profileImageURL {
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
      .frame(width: 24, height: 24)
      .clipShape(.circle)
    } else {
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: 24, height: 24)
        .overlay {
          Text("😀")
            .font(.caption)
        }
    }
  }

  var header: some View {
    HStack {
      profileImage

      Text(post.authorName)
        .fontWeight(.semibold)

      Text(post.createdAt.timeAgoDisplay)
        .foregroundStyle(.secondary)

      Spacer()

      Menu("More", systemImage: "ellipsis") { }
        .labelStyle(.iconOnly)
    }
    .tint(.secondary)
    .padding(.horizontal)
  }

  @ViewBuilder
  var content: some View {
    Text(post.content)
      .padding(.horizontal)
    if !post.images.isEmpty {
      PostImagesStrip(images: post.images)
    }
  }

  var footer: some View {
    HStack {
      PostVoteButton(
        myVote: nil,
        votes: post.upvotes - post.downvotes,
        onDownvote: {
        }, onUpvote: {
        }
      )

      PostCommentButton(commentCount: post.commentCount) {
      }

      Spacer()

      PostBookmarkButton()

      PostShareButton()
    }
    .padding(.horizontal)
    .padding(.top, 4)
  }
}

#Preview {
  FeedPostRow(post: .constant(FeedPost.mock))
}
