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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        FeedPostRow(post: $post, onPostDeleted: nil)

        Divider()
          .padding(.horizontal)

        comments
      }
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
    LazyVStack {
      
    }
  }
}

#Preview {
  FeedPostView(post: .constant(FeedPost.mock))
}
