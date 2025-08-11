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
  @State private var targetComment: AraPostComment? = nil
  @State private var commentOnEdit: AraPostComment? = nil
  @State private var isUploadingComment: Bool = false

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
    .onKeyboardDismiss {
      if comment.isEmpty {
        targetComment = nil
      }
    }
    .contentMargins(.bottom, 64)
    .navigationTitle(viewModel.post.board?.name.localized() ?? "")
    .safeAreaBar(edge: .bottom) {
      inputBar
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu("More", systemImage: "ellipsis") {
          if viewModel.post.isMine == false {
            // show report and block menus
            Menu("Report", systemImage: "exclamationmark.triangle.fill") {
              Button("Hate Speech") { }
              Button("Unauthorized Sales") { }
              Button("Spam") { }
              Button("False Information") { }
              Button("Defamation") { }
              Button("Other") { }
            }

            Button("Block", systemImage: "person.slash.fill") { }

            Divider()
          }/* else if viewModel.post.isMine == true {*/
            // show edit post button
//            Button("Edit", systemImage: "square.and.pencil") { }
//          }

          Button("Summarise", systemImage: "text.append") { }

          if viewModel.post.isMine == true {
            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) { }
          }
        }
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
      if viewModel.post.comments.isEmpty {
        Divider()
        ContentUnavailableView("No one has commented yet.", systemImage: "text.bubble", description: Text("Be the first one to share your thoughts."))
          .scaleEffect(0.8)
      } else {
        ForEach($viewModel.post.comments) { $comment in
          VStack(spacing: 12) {
            PostCommentCell(
              comment: $comment,
              isThreaded: false,
              onComment: {
                targetComment = comment
                isWritingCommentFocusState = true
              },
              onDelete: {
                viewModel.post.commentCount -= 1
              },
              onEdit: {
                withAnimation(.spring) {
                  self.comment = comment.content ?? ""
                  targetComment = nil
                  commentOnEdit = comment
                }
                isWritingCommentFocusState = true
              }
            )

            // Threads
            ForEach($comment.comments) { $thread in
              PostCommentCell(
                comment: $thread,
                isThreaded: true,
                onComment: {
                  targetComment = thread
                  isWritingCommentFocusState = true
                },
                onDelete: {
                  viewModel.post.commentCount -= 1
                },
                onEdit: {
                  withAnimation(.spring) {
                    self.comment = thread.content ?? ""
                    targetComment = nil
                    commentOnEdit = comment
                  }
                  isWritingCommentFocusState = true
                }
              )
            }
          }
        }
      }
    }
    .padding(.top, 4)
  }

  private var footer: some View {
    HStack {
      PostVoteButton(
        myVote: viewModel.post.myVote,
        votes: viewModel.post.upvotes - viewModel.post.downvotes,
        onDownvote: {
          Task {
            await viewModel.downvote()
          }
        }, onUpvote: {
          Task {
            await viewModel.upvote()
          }
        }
      )
      .disabled(viewModel.post.isMine ?? false)

      PostCommentButton(commentCount: viewModel.post.commentCount) {
        targetComment = nil
        isWritingCommentFocusState = true
      }

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
    HStack(alignment: .bottom) {
      // comment textfield
      VStack(alignment: .leading) {
        if commentOnEdit != nil {
          HStack {
            Text("Editing")
              .textCase(.uppercase)
              .font(.footnote)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)

            Spacer()

            Button("Cancel", systemImage: "xmark") {
              withAnimation(.spring) {
                comment = ""
                commentOnEdit = nil
              }
            }
            .font(.caption)
            .labelStyle(.iconOnly)
          }
        }

        HStack {
          if !isWritingComment && comment.isEmpty {
            profilePicture
              .transition(.move(edge: .leading).combined(with: .opacity))
          }

          TextField(text: $comment, prompt: Text(placeholder), axis: .vertical, label: {})
            .focused($isWritingCommentFocusState)
        }
      }
      .padding(12)
      .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 24))
      .tint(.primary)

      // write comment button
      if !comment.isEmpty {
        Button(action: {
          guard !comment.isEmpty else { return }

          Task {
            isUploadingComment = true
            defer { isUploadingComment = false }
            do {
              if let commentOnEdit = commentOnEdit {
                try await viewModel.editComment(commentID: commentOnEdit.id, content: comment)
              } else if let targetComment = targetComment {
                try await viewModel.writeThreadedComment(commentID: targetComment.id, content: comment)
              } else {
                try await viewModel.writeComment(content: comment)
              }
              targetComment = nil
              commentOnEdit = nil
              comment = ""
              isWritingCommentFocusState = false
            } catch {
              logger.error(error)
              // TODO: handle error here
            }
          }
        }, label: {
          if isUploadingComment {
            ProgressView()
              .tint(.white)
          } else {
            Label("Send", systemImage: "paperplane")
              .labelStyle(.iconOnly)
              .tint(.white)
          }
        })
        .fontWeight(.medium)
        .padding(12)
        .glassEffect(.regular.tint(.accent).interactive(), in: .circle)
        .disabled(comment.isEmpty)
        .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .disabled(isUploadingComment)
    .padding(.horizontal)
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

  var placeholder: String {
    if let targetComment = targetComment {
      return "reply to \(targetComment.author.profile.nickname)"
    }

    if let commentOnEdit = commentOnEdit {
      return commentOnEdit.content ?? ""
    }

    return "reply as \(viewModel.post.myCommentProfile?.profile.nickname ?? "anonymous")"
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
