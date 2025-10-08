//
//  FeedPostView.swift
//  soap
//
//  Created by Soongyu Kwon on 24/08/2025.
//

import SwiftUI
import NukeUI
import Factory
import BuddyDomain

struct FeedPostView: View {
  @Binding var post: FeedPost
  let onDelete: (() -> Void)?

  @Environment(\.keyboardShowing) private var keyboardShowing
  @Environment(\.dismiss) private var dismiss

  @State private var showDeleteConfirmation: Bool = false

  @State private var feedUser: FeedUser? = nil

  @FocusState private var isWritingCommentFocusState: Bool
  @State private var targetComment: FeedComment? = nil
  @State private var isUploadingComment: Bool = false
  
  @State private var showAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""

  @State private var showTranslateSheet: Bool = false

  // MARK: - Dependencies
  @Injected(
    \.feedPostRepository
  ) private var feedPostRepository: FeedPostRepositoryProtocol
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @State private var viewModel: FeedPostViewModelProtocol = FeedPostViewModel()

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          FeedPostRow(post: $post, onPostDeleted: nil, onComment: {
            targetComment = nil
            isWritingCommentFocusState = true
          }, showFullContent: true)

          comments
        }
      }
      .task {
        await viewModel.fetchComments(postID: post.id)
        self.feedUser = await userUseCase.feedUser
      }
      .refreshable {
        await viewModel.fetchComments(postID: post.id)
      }
      .navigationTitle("Post")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarVisibility(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu("More", systemImage: "ellipsis") {
            Button("Translate", systemImage: "translate") { showTranslateSheet = true }
            Divider()
            if post.isAuthor {
              Button("Delete", systemImage: "trash", role: .destructive) {
                showDeleteConfirmation = true
              }
            } else {
              Menu("Report", systemImage: "exclamationmark.triangle.fill") {
                ForEach(FeedReportType.allCases) { reason in
                  Button(reason.description) {
                    Task {
                      do {
                        try await feedPostRepository.reportPost(postID: post.id, reason: reason, detail: "")
                        showAlert(title: String(localized: "Report Submitted"), message: String(localized: "Your report has been submitted successfully."))
                      } catch {
                        // TODO: error handling
                      }
                    }
                  }
                }
              }
            }
          }
          .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
              onDelete?()
              dismiss()
            }
            Button("Cancel", role: .cancel) { }
          } message: {
            Text("Are you sure you want to delete this post?")
          }
        }
      }
      .translationPresentation(isPresented: $showTranslateSheet, text: post.content)
      .scrollDismissesKeyboard(.immediately)
      .safeAreaBar(edge: .bottom) {
        inputBar(proxy: proxy)
      }
      .alert(alertTitle, isPresented: $showAlert, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(alertMessage)
      })
    }
  }

  private func inputBar(proxy: ScrollViewProxy) -> some View {
    HStack(alignment: .bottom) {
      // comment textfield
      VStack(alignment: .leading) {
        // maybe some images and anonymous selector
        TextField(
          text: $viewModel.text,
          prompt: Text(
            targetComment != nil ? "Write a reply to \(targetComment?.authorName ?? "unknown")" : "Write a comment"
          ),
          axis: .vertical,
          label: {
          }
        )
        .focused($isWritingCommentFocusState)

        if keyboardShowing {
          Toggle("Write Anonymously", isOn: $viewModel.isAnonymous)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .fontDesign(.rounded)
            .font(.callout)
            .fontWeight(.medium)
        }
      }
      .padding(12)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))

      // write comment button
      if !viewModel.text.isEmpty {
        Button(action: {
          guard !viewModel.text.isEmpty else { return }

          Task {
            isUploadingComment = true
            defer { isUploadingComment = false }
            do {
              var uploadedComment: FeedComment? = nil
              if let targetComment {
                uploadedComment = try await viewModel.writeReply(commentID: targetComment.id)
              } else {
                uploadedComment = try await viewModel.writeComment(postID: post.id)
              }
              post.commentCount += 1
              targetComment = nil
              viewModel.text = ""
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
        .disabled(viewModel.text.isEmpty)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .disabled(isUploadingComment)
      }
    }
    .padding(keyboardShowing ? [.horizontal, .vertical] : [.horizontal])
    .animation(.spring, value: keyboardShowing)
    .animation(
      .spring(duration: 0.35, bounce: 0.4, blendDuration: 0.15),
      value: viewModel.text.isEmpty
    )
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
            FeedCommentRow(comment: .constant(comment), isReply: false, onReply: nil)
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
            .contentTransition(.numericText(value: Double(post.commentCount)))
            .animation(.spring, value: post.commentCount)

          ForEach($viewModel.comments) { $comment in
            FeedCommentRow(comment: $comment, isReply: false, onReply: {
              targetComment = comment
              isWritingCommentFocusState = true
            })
            .padding(.horizontal)
            .id(comment.id)

            if !comment.replies.isEmpty {
              VStack(spacing: 12) {
                ForEach($comment.replies) { $reply in
                  FeedCommentRow(comment: $reply, isReply: true, onReply: nil)
                    .padding(.horizontal)
                    .id(reply.id)
                }
              }
            }

            Divider()
              .padding(.horizontal)
          }
        }
        .animation(.spring, value: viewModel.comments)
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "text.bubble", description: Text(message))
          .scaleEffect(0.8)
      }
    }
  }
  
  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
}

#Preview {
  FeedPostView(post: .constant(FeedPost.mock), onDelete: nil)
}
