//
//  FeedPostView.swift
//  soap
//
//  Created by Soongyu Kwon on 24/08/2025.
//

import SwiftUI
import NukeUI
import Factory

struct FeedPostView: View {
  @Binding var post: FeedPost

  @State private var showDeleteConfirmation: Bool = false

  // MARK: - Dependencies
  @Injected(
    \.feedPostRepository
  ) private var feedPostRepository: FeedPostRepositoryProtocol
  @State private var viewModel: FeedPostViewModelProtocol = FeedPostViewModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        FeedPostRow(post: $post, onPostDeleted: nil)

        comments
      }
    }
    .task {
      await viewModel.fetchComments(postID: post.id)
    }
    .navigationTitle("Post")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarVisibility(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu("More", systemImage: "ellipsis") {
          if post.isAuthor {
            Button("Delete", systemImage: "trash", role: .destructive) {
              showDeleteConfirmation = true
            }
          }
        }
        .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
          Button("Delete", role: .destructive) {

          }
          Button("Cancel", role: .cancel) { }
        } message: {
          Text("Are you sure you want to delete this post?")
        }
      }
    }
  }

  private var comments: some View {
    Group {
      switch viewModel.state {
      case .loading:
        VStack(alignment: .leading, spacing: 16) {
          Divider()
            .padding(.horizontal)

          Text("\(post.commentCount) comments")
            .font(.headline)
            .padding(.horizontal)

          ForEach(FeedComment.mockList.prefix(4)) { comment in
            FeedCommentRow(comment: .constant(comment), isReply: false)
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

          Text("\(post.commentCount) comments")
            .font(.headline)
            .padding(.horizontal)

          ForEach($viewModel.comments) { $comment in
            FeedCommentRow(comment: $comment, isReply: false)
              .padding(.horizontal)

            if !comment.replies.isEmpty {
              VStack(spacing: 12) {
                ForEach($comment.replies) { $reply in
                  FeedCommentRow(comment: $reply, isReply: true)
                    .padding(.horizontal)
                }
              }
            }

            Divider()
              .padding(.horizontal)
          }
        }
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "text.bubble", description: Text(message))
          .scaleEffect(0.8)
      }
    }
  }
}

#Preview {
  FeedPostView(post: .constant(FeedPost.mock))
}
