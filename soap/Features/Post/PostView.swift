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
    .navigationTitle(viewModel.post.board?.name.localized() ?? "")
    .safeAreaBar(edge: .bottom) {
      inputBar
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu("More", systemImage: "ellipsis") { }
      }
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
        if comments.isEmpty {
          ContentUnavailableView("No one has commented yet.", systemImage: "text.bubble", description: Text("Be the first one to share your thoughts."))
            .scaleEffect(0.8)
        } else {
          ForEach(comments) { comment in
            VStack(spacing: 12) {
              PostCommentCell(
                comment: comment,
                isThreaded: false,
                onDownvote: {
                  Task {
                    await viewModel.downvoteComment(commentID: comment.id)
                  }
                },
                onUpvote: {
                  Task {
                    await viewModel.upvoteComment(commentID: comment.id)
                  }
                },
                onComment: nil
              )

              // Threads
              if let threads = comment.comments {
                ForEach(threads) { thread in
                  PostCommentCell(
                    comment: thread,
                    isThreaded: true,
                    onDownvote: {
                      Task {
                        await viewModel.downvoteComment(commentID: thread.id)
                      }
                    },
                    onUpvote: {
                      Task {
                        await viewModel.upvoteComment(commentID: thread.id)
                      }
                    },
                    onComment: nil
                  )
                }
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
      PostVoteButton(myVote: viewModel.post.myVote, votes: viewModel.post.upvotes - viewModel.post.downvotes, onDownvote: {
        Task {
          await viewModel.downvote()
        }
      }, onUpvote: {
        Task {
          await viewModel.upvote()
        }
      })
      .disabled(viewModel.post.isMine ?? false)

      PostCommentButton(commentCount: viewModel.post.commentCount)

      Spacer()

      PostBookmarkButton()

      PostShareButton()
    }
    .font(.callout)
  }

  @ViewBuilder
  private var content: some View {
    if let content = viewModel.post.content {
      DynamicHeightWebView(
        htmlString: content,
        dynamicHeight: $htmlHeight,
        onLinkTapped: { url in
          self.tappedURL = url
        }
      )
      .frame(height: htmlHeight)
    } else {
      ProgressView()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)

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
          profilePicture
            .transition(.move(edge: .leading).combined(with: .opacity))
        }

        TextField(text: $comment, prompt: Text("reply as \(viewModel.post.myCommentProfile?.profile.nickname ?? "anonymous")"), label: {})
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

  var profilePicture: some View {
    Group {
      if let url = viewModel.post.myCommentProfile?.profile.profilePictureURL {
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

  var title: AttributedString {
    var result = AttributedString()

    if let topicName = viewModel.post.topic?.name.localized() {
      var topicAttr = AttributedString("[\(topicName)] ")
      topicAttr.font = .headline
      topicAttr.foregroundColor = .accentColor
      result.append(topicAttr)
    }

    var titleAttr = AttributedString(viewModel.post.title ?? "Untitled")
    titleAttr.font = .headline
    titleAttr.foregroundColor = .primary
    result.append(titleAttr)

    return result
  }
}

#Preview {
  NavigationStack {
    PostView(post: AraPost.mock)
  }
}
