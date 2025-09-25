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
  @Environment(\.dismiss) private var dismiss

  @Environment(\.keyboardShowing) var keyboardShowing

  @State private var htmlHeight: CGFloat = .zero
  @State private var tappedURL: URL?

  @State private var comment: String = ""
  @FocusState private var isWritingCommentFocusState: Bool
  @State private var isWritingComment: Bool = false
  @State private var targetComment: AraPostComment? = nil
  @State private var commentOnEdit: AraPostComment? = nil
  @State private var isUploadingComment: Bool = false

  @State private var selectedAuthor: AraPostAuthor? = nil

  @State private var showTranslationView: Bool = false
  @State private var showDeleteConfirmation: Bool = false

  @State private var summarisedContent: String? = nil

  @State private var showAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""

  let onPostDeleted: ((Int) -> Void)?

  init(post: AraPost, onPostDeleted: ((Int) -> Void)? = nil) {
    _viewModel = State(initialValue: PostViewModel(post: post))
    self.onPostDeleted = onPostDeleted
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        Group {
          header

          content

          footer

          comments
        }
        .padding()
        .animation(.spring(), value: summarisedContent)
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
        inputBar(proxy: proxy)
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          actionsMenu
            .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
              Button("Delete", role: .destructive) {
                Task {
                  do {
                    try await viewModel.deletePost()
                    onPostDeleted?(viewModel.post.id)
                    dismiss()
                  } catch {
                    showAlert(title: "Error", message: "Failed to delete a post. Please try again later.")
                  }
                }
              }
              Button("Cancel", role: .cancel) { }
            } message: {
              Text("Are you sure you want to delete this post?")
            }
        }
      }
      .alert(alertTitle, isPresented: $showAlert, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(alertMessage)
      })
      .sheet(item: $tappedURL) { url in
        SafariViewWrapper(url: url)
      }
      .sheet(isPresented: $showTranslationView) {
        PostTranslationView(post: viewModel.post)
      }
      .navigationDestination(item: $selectedAuthor) { author in
        UserPostListView(user: author)
      }
      .task {
        await viewModel.fetchPost()
      }
      .refreshable {
        await viewModel.fetchPost()
      }
    }
  }

  private var actionsMenu: some View {
    Menu("More", systemImage: "ellipsis") {
      if viewModel.post.isMine == false {
        // show report and block menus
        Menu("Report", systemImage: "exclamationmark.triangle.fill") {
          Button("Hate Speech") {
            Task {
              try? await viewModel.report(type: .hateSpeech)
              showAlert(title: "Report Submitted", message: "Your report has been submitted successfully.")
            }
          }
          Button("Unauthorized Sales") {
            Task {
              try? await viewModel.report(type: .unauthorizedSales)
              showAlert(title: "Report Submitted", message: "Your report has been submitted successfully.")
            }
          }
          Button("Spam") {
            Task {
              try? await viewModel.report(type: .spam)
              showAlert(title: "Report Submitted", message: "Your report has been submitted successfully.")
            }
          }
          Button("False Information") {
            Task {
              try? await viewModel.report(type: .falseInformation)
              showAlert(title: "Report Submitted", message: "Your report has been submitted successfully.")
            }
          }
          Button("Defamation") {
            Task {
              try? await viewModel.report(type: .defamation)
              showAlert(title: "Report Submitted", message: "Your report has been submitted successfully.")
            }
          }
          Button("Other") {
            Task {
              try? await viewModel.report(type: .other)
              showAlert(title: "Report Submitted", message: "Your report has been submitted successfully.")
            }
          }
        }
      }

      if viewModel.post.isMine == false { Divider () }

      Button("Translate", systemImage: "translate") {
        showTranslationView = true
      }

      if viewModel.isFoundationModelsAvailable {
        Button("Summarise", systemImage: "text.append") {
          summarisedContent = ""
          Task {
            summarisedContent = await viewModel.summarisedContent()
          }
        }
        .disabled(summarisedContent != nil)
      }

      if viewModel.post.isMine == true { Divider () }

      if viewModel.post.isMine == true {
        Button("Delete", systemImage: "trash", role: .destructive) {
          showDeleteConfirmation = true
        }
      }
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
            .id(comment.id)

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
                    commentOnEdit = thread
                  }
                  isWritingCommentFocusState = true
                }
              )
              .id(thread.id)
            }
          }
        }
      }
    }
    .padding(.top, 4)
    .animation(.spring, value: viewModel.post.comments)
  }

  private var footer: some View {
    HStack {
      PostVoteButton(
        myVote: viewModel.post.myVote,
        votes: viewModel.post.upvotes - viewModel.post.downvotes,
        onDownvote: {
          await viewModel.downvote()
        }, onUpvote: {
          await viewModel.upvote()
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
    if let summarisedContent {
      SummarisationView(text: summarisedContent)
        .padding(.bottom)
        .transition(.asymmetric(
          insertion: .offset(y: -10).combined(with: .opacity),
          removal: .opacity
        ))
    }

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

      Button(action: {
        selectedAuthor = viewModel.post.author
      }, label: {
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

          if viewModel.post.author.username != "anonymous" {
            Image(systemName: "chevron.right")
          }
        }
        .font(.subheadline)
      })
      .tint(.primary)
      .disabled(viewModel.post.author.username == "anonymous")

      Divider()
        .padding(.vertical, 4)
    }
  }

  private func inputBar(proxy: ScrollViewProxy) -> some View {
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
            .onChange(of: isWritingCommentFocusState) {
              print(isWritingCommentFocusState)
              isWritingComment = isWritingCommentFocusState
            }
        }
      }
      .padding(12)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
      .tint(.primary)

      // write comment button
      if !comment.isEmpty {
        Button(action: {
          guard !comment.isEmpty else { return }

          Task {
            isUploadingComment = true
            defer { isUploadingComment = false }
            do {
              var uploadedComment: AraPostComment? = nil
              if let commentOnEdit = commentOnEdit {
                uploadedComment = try await viewModel.editComment(commentID: commentOnEdit.id, content: comment)
              } else if let targetComment = targetComment {
                uploadedComment = try await viewModel.writeThreadedComment(commentID: targetComment.id, content: comment)
              } else {
                uploadedComment = try await viewModel.writeComment(content: comment)
              }
              targetComment = nil
              commentOnEdit = nil
              comment = ""
              isWritingCommentFocusState = false

              withAnimation(.spring) {
                proxy.scrollTo(uploadedComment?.id, anchor: .center)
              }
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
        .disabled(isUploadingComment)
      }
    }
    .padding(keyboardShowing ? [.horizontal, .vertical] : [.horizontal])
    .animation(.spring, value: keyboardShowing)
    .animation(
      .spring(duration: 0.35, bounce: 0.4, blendDuration: 0.15),
      value: comment.isEmpty
    )
    .animation(
      .spring(duration: 0.2, bounce: 0.2, blendDuration: 0.1),
      value: isWritingComment
    )
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

  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
}

#Preview {
  PostView(post: AraPost.mock, onPostDeleted: nil)
}
