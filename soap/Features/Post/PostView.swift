//
//  PostView.swift
//  soap
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI
import NukeUI
import WebKit

struct PostView: View {
  @State private var viewModel: PostViewModelProtocol

  @State private var htmlHeight: CGFloat = .zero
  @State private var tappedURL: URL?

  @State private var comment: String = ""
  @FocusState private var isWritingCommentFocusState: Bool
  @State private var isWritingComment: Bool = false

  init(post: AraPost) {
    _viewModel = State(initialValue: PostViewModel(post: post))
  }

  var body: some View {
    ScrollView {
      Group {
        header

        content

        footer

        comments
      }
      .padding()
    }
    .scrollDismissesKeyboard(.interactively)
    .contentMargins(.bottom, 64)
    .safeAreaBar(edge: .bottom) {
      inputBar
    }
    .sheet(item: $tappedURL) { url in
      SafariViewWrapper(url: url)
    }
    .task {
      await viewModel.fetchPost()
    }
  }

  private var comments: some View {
    VStack(spacing: 16) {
      // Main comment
      if let comments = viewModel.post.comments {
        ForEach(comments) { comment in
          VStack(spacing: 12) {
            PostCommentCell(comment: comment)

            // Threads
            if let threads = comment.comments {
              ForEach(threads) { thread in
                PostThreadedCommentCell(comment: thread)
              }
            }
          }
        }
      }
    }
    .padding(.top, 4)
  }

  private var footer: some View {
    HStack {
      PostVoteButton(myVote: viewModel.post.myVote, votes: viewModel.post.upvotes - viewModel.post.downvotes, onDownvote: { }, onUpvote: { })

      PostCommentButton(commentCount: viewModel.post.commentCount)

      Spacer()

      PostBookmarkButton()

      PostShareButton()
    }
    .font(.callout)
  }

  @ViewBuilder
  private var content: some View {
    DynamicHeightWebView(
      htmlString: viewModel.post.content ?? "",
      dynamicHeight: $htmlHeight,
      onLinkTapped: { url in
        self.tappedURL = url
      }
    )
      .frame(height: htmlHeight)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(viewModel.post.title ?? "Untitled")
        .font(.headline)

      HStack {
        Text(viewModel.post.createdAt.formattedString)
        Text("\(viewModel.post.views) views")
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      HStack {
        if let url = viewModel.post.author.profile.profilePictureURL {
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
          .frame(width: 28, height: 28)
          .clipShape(.circle)
        } else {
          Circle()
            .fill(Color.secondarySystemBackground)
            .frame(width: 28, height: 28)
        }

        Text(viewModel.post.author.profile.nickname)
          .fontWeight(.medium)

        Image(systemName: "chevron.right")
      }
      .font(.subheadline)

      Divider()
        .padding(.vertical, 4)
    }
  }

  private var inputBar: some View {
    HStack {
      HStack {
        if !isWritingComment && comment.isEmpty {
          Circle()
            .frame(width: 21, height: 21)
            .transition(.move(edge: .leading).combined(with: .opacity))
        }

        TextField(text: $comment, prompt: Text("reply as anonymous"), label: {})
          .focused($isWritingCommentFocusState)
      }
      .padding(12)
      .glassEffect(.clear.interactive())
      .tint(.primary)

      if !comment.isEmpty {
        Button("send", systemImage: "paperplane") { }
          .fontWeight(.medium)
          .labelStyle(.iconOnly)
          .tint(.white)
          .padding(12)
          .glassEffect(.regular.tint(.black).interactive(), in: .circle)
          .disabled(comment.isEmpty)
          .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .padding()
    .animation(
      .spring(duration: 0.35, bounce: 0.4, blendDuration: 0.15),
      value: comment.isEmpty
    )
    .animation(
      .spring(duration: 0.2, bounce: 0.2, blendDuration: 0.1),
      value: isWritingComment
    )
    .onChange(of: isWritingCommentFocusState) {
      isWritingComment = isWritingCommentFocusState
    }
  }
}

#Preview {
  NavigationStack {
    PostView(post: AraPost.mock)
  }
}
