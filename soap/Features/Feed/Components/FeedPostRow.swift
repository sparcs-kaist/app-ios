//
//  FeedPostRow.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI
import Factory

struct FeedPostRow: View {
  @Binding var post: FeedPost
  let onPostDeleted: ((String) -> Void)?

  @State private var showDeleteConfirmation: Bool = false

  // MARK: - Dependencies
  @Injected(\.feedPostRepository) private var feedPostRepository: FeedPostRepositoryProtocol

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

      Menu("More", systemImage: "ellipsis") {
        if post.isAuthor {
          Button("Delete", systemImage: "trash", role: .destructive) {
            showDeleteConfirmation = true
          }
        }
      }
      .labelStyle(.iconOnly)
      .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
        Button("Delete", role: .destructive) {
          Task {
            onPostDeleted?(post.id)
          }
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("Are you sure you want to delete this post?")
      }
    }
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
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: nil)
}
