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
        header

        content

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
        .font(.callout)

      // onPostDeleted == nil here means FeedPostRow is in the FeedPostView.
      Text(onPostDeleted != nil ? post.createdAt.timeAgoDisplay : post.createdAt.relativeTimeString)
        .foregroundStyle(.secondary)
        .font(.callout)

      Spacer()

      if onPostDeleted != nil {
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
        myVote: post.myVote == .up ? true : post.myVote == .down ? false : nil,
        votes: post.upvotes - post.downvotes,
        onDownvote: {
          await downvote()
        }, onUpvote: {
          await upvote()
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

  // MARK: - Functions
  private func upvote() async {
    let previousMyVote: FeedVoteType? = post.myVote
    let previousUpvotes: Int = post.upvotes

    do {
      if previousMyVote == .up {
        // cancel upvote
        post.myVote = nil
        post.upvotes -= 1
        try await feedPostRepository.deleteVote(postID: post.id)
      } else {
        // upvote
        if previousMyVote == .down {
          // remove downvote if there was
          post.downvotes -= 1
        }
        post.myVote = .up
        post.upvotes += 1
        try await feedPostRepository.vote(postID: post.id, type: .up)
      }
    } catch {
      logger.error(error)
      post.myVote = previousMyVote
      post.upvotes = previousUpvotes
    }
  }

  private func downvote() async {
    let previousMyVote: FeedVoteType? = post.myVote
    let previousDownvotes: Int = post.downvotes

    do {
      if previousMyVote == .down {
        // cancel downvote
        post.myVote = nil
        post.downvotes -= 1
        try await feedPostRepository.deleteVote(postID: post.id)
      } else {
        // downvote
        if previousMyVote == .up {
          // remove downvote if there was
          post.upvotes -= 1
        }
        post.myVote = .down
        post.downvotes += 1
        try await feedPostRepository.vote(postID: post.id, type: .down)
      }
    } catch {
      logger.error(error)
      post.myVote = previousMyVote
      post.downvotes = previousDownvotes
    }
  }
}

#Preview {
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: nil)
}
