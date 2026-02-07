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
import BuddyFeatureShared
import BuddyPreviewSupport

struct FeedPostView: View {
  @Binding var post: FeedPost
  let onDelete: (() async throws -> Void)?

  @Environment(\.keyboardShowing) private var keyboardShowing
  @Environment(\.dismiss) private var dismiss

  @State private var showDeleteConfirmation: Bool = false

  @FocusState private var isWritingCommentFocusState: Bool
  @State private var targetComment: FeedComment? = nil

  @State private var showTranslateSheet: Bool = false

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
      .task(id: post.id) {
        await viewModel.fetchComments(postID: post.id, initial: true)
        await viewModel.fetchFeedUser()
      }
      .refreshable {
        await viewModel.fetchComments(postID: post.id, initial: false)
      }
      .navigationTitle("Post")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarVisibility(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          moreMenu
        }
      }
      .translationPresentation(isPresented: $showTranslateSheet, text: post.content)
      .scrollDismissesKeyboard(.immediately)
      .safeAreaBar(edge: .bottom) {
        inputBar(proxy: proxy)
      }
      .alert(
        viewModel.alertState?.title ?? "Error",
        isPresented: $viewModel.isAlertPresented,
        actions: {
          Button("Okay", role: .close) { }
        }, message: {
          Text(viewModel.alertState?.message ?? "Unexpected Error")
        }
      )
    }
  }

  private var moreMenu: some View {
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
                await viewModel.reportPost(postID: post.id, reason: reason)
              }
            }
          }
        }
      }
    }
    .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
      Button("Delete", role: .destructive) {
        Task {
          do {
            try await onDelete?()
            dismiss()
          } catch {
            viewModel.alertState = .init(
              title: String(localized: "Unable to delete post."),
              message: error.localizedDescription
            )
            viewModel.isAlertPresented = true
          }
        }
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("Are you sure you want to delete this post?")
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
            if let uploadedComment = await viewModel.submitComment(postID: post.id, replyingTo: targetComment) {
              post.commentCount += 1
              targetComment = nil
              isWritingCommentFocusState = false

              withAnimation(.spring) {
                proxy.scrollTo(uploadedComment.id, anchor: .center)
              }
            }
          }
        }, label: {
          if viewModel.isSubmittingComment {
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
        .glassEffect(.regular.tint(Color.accentColor).interactive(), in: .circle)
        .disabled(viewModel.text.isEmpty || viewModel.isSubmittingComment)
        .transition(.move(edge: .trailing).combined(with: .opacity))
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
}

// MARK: - Previews

// IGNORES COMMENT COUNT BEING WRONG SINCE THEY ARE NOT BEING COUNTED DYNAMICALLY BASED ON ACTUAL COMMENTS. IT IS BEING PULLED FROM POST META DATA.

#Preview("Post Detail") {
  @Previewable @State var spoilerContents = SpoilerContents()
  let _ = Container.setupFeedPreview()
  NavigationStack {
    FeedPostView(post: .constant(FeedPost.mock), onDelete: nil)
      .environment(spoilerContents)
      .addKeyboardVisibilityToEnvironment()
  }
}

#Preview("With Comments") {
  @Previewable @State var spoilerContents = SpoilerContents()
  let _ = Container.setupFeedPreview()
  NavigationStack {
    FeedPostView(post: .constant(FeedPost.mockList[6]), onDelete: nil)
      .environment(spoilerContents)
      .addKeyboardVisibilityToEnvironment()
  }
}

#Preview("Author Post") {
  @Previewable @State var spoilerContents = SpoilerContents()
  let _ = Container.setupFeedPreview()
  NavigationStack {
    FeedPostView(post: .constant(FeedPost.mockList[0]), onDelete: {})
      .environment(spoilerContents)
      .addKeyboardVisibilityToEnvironment()
  }
}
