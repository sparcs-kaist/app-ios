//
//  PostView.swift
//  soap
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import Haptica
import FirebaseAnalytics
import BuddyFeatureShared
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostView")

public struct PostView: View {
  @State private var viewModel: PostViewModelProtocol
  @Environment(\.dismiss) private var dismiss

  @Environment(\.keyboardShowing) var keyboardShowing

  @State private var htmlHeight: CGFloat = .zero
  @State private var tappedURL: URL?

  @State private var isWebViewLoading: Bool = false
  @State private var webViewLoadError: DynamicHeightWebView.LoadError?
  @State private var webViewReloadToken: Int = 0

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

  let onPostDeleted: ((Int) -> Void)?

  public init(post: AraPost, onPostDeleted: ((Int) -> Void)? = nil) {
    _viewModel = State(initialValue: PostViewModel(post: post))
    self.onPostDeleted = onPostDeleted
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        Group {
          PostHeader(
            title: title,
            createdAtText: viewModel.post.createdAt.formattedString,
            views: viewModel.post.views,
            authorProfileURL: viewModel.post.author.profile.profilePictureURL,
            authorNickname: viewModel.post.author.profile.nickname,
            isAnonymous: viewModel.post.author.username == "anonymous",
            onAuthorTapped: { selectedAuthor = viewModel.post.author }
          )

          PostContent(
            summarisedContent: summarisedContent,
            requestProvider: { viewModel.makePostRequest() },
            onLinkTapped: { tappedURL = $0 }
          )

          PostFooter(
            myVote: viewModel.post.myVote,
            votes: viewModel.post.upvotes - viewModel.post.downvotes,
            isMine: viewModel.post.isMine,
            commentCount: viewModel.post.commentCount,
            isBookmarked: viewModel.post.myScrap,
            shareURL: Constants.araPostURL.appending(path: String(viewModel.post.id)),
            onUpvote: { await viewModel.upvote() },
            onDownvote: { await viewModel.downvote() },
            onToggleBookmark: { await viewModel.toggleBookmark() },
            onCommentTapped: {
              targetComment = nil
              isWritingCommentFocusState = true
            }
          )

          PostCommentsSection(
            comments: $viewModel.post.comments,
            onReply: { selectedComment in
              targetComment = selectedComment
              isWritingCommentFocusState = true
            },
            onCommentDeleted: {
              viewModel.post.commentCount -= 1
            },
            onEdit: { selectedComment in
              withAnimation(.spring) {
                comment = selectedComment.content ?? ""
                targetComment = nil
                commentOnEdit = selectedComment
              }
              isWritingCommentFocusState = true
            },
            onUpvote: { target in
              await viewModel.upvoteComment(comment: target)
            },
            onDownvote: { target in
              await viewModel.downvoteComment(comment: target)
            },
            onReport: { commentID, type in
              try await viewModel.reportComment(commentID: commentID, type: type)
            },
            onDeleteComment: { target in
              await viewModel.deleteComment(comment: target)
            }
          )
          .padding(.top, 4)
          .animation(.spring, value: viewModel.post.comments.map(\.id))
        }
        .padding()
        .contentWidth()
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
            .confirmationDialog(String(localized: "Delete Post", bundle: .module), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
              Button(String(localized: "Delete", bundle: .module), role: .destructive) {
                Task {
                  do {
                    try await viewModel.deletePost()
                    onPostDeleted?(viewModel.post.id)
                    dismiss()
                  } catch {
                    logger.error("Failed to delete post: \(error.localizedDescription, privacy: .public)")
                    viewModel.alertState = .init(
                      title: String(localized: "Unable to delete post.", bundle: .module),
                      message: error.localizedDescription
                    )
                    viewModel.isAlertPresented = true
                  }
                }
              }
              Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
            } message: {
              Text("Are you sure you want to delete this post?", bundle: .module)
            }
        }
      }
      .background {
        BackgroundGradientView(color: .red)
          .ignoresSafeArea()
      }
      .alert(viewModel.alertState?.title ?? String(localized: "Error", bundle: .module), isPresented: $viewModel.isAlertPresented, actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
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
    .analyticsScreen(name: "Ara Post", class: String(describing: Self.self), extraParameters: [
      "is_author": viewModel.post.isMine ?? false,
      "has_comments": viewModel.post.commentCount > 0
    ])
  }

  private var actionsMenu: some View {
    Menu(String(localized: "More", bundle: .module), systemImage: "ellipsis") {
      if viewModel.post.isMine == false {
        // show report and block menus
        Menu(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle.fill") {
          ForEach(AraContentReportType.allCases, id: \.self) { type in
            Button(type.prettyString) {
              Task {
                await report(type: type)
              }
            }
          }
        }
      }

      if viewModel.post.isMine == false { Divider () }

      Button(String(localized: "Translate", bundle: .module), systemImage: "translate") {
        showTranslationView = true
      }

      if viewModel.isFoundationModelsAvailable {
        Button(String(localized: "Summarise", bundle: .module), systemImage: "text.append") {
          summarisedContent = ""
          Task {
            Haptic.start.generate()
            summarisedContent = await viewModel.summarisedContent()
            Haptic.success.generate()
          }
        }
        .disabled(summarisedContent != nil)
      }

      if viewModel.post.isMine == true { Divider () }

      if viewModel.post.isMine == true {
        Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
          showDeleteConfirmation = true
        }
      }
    }
  }

  private func inputBar(proxy: ScrollViewProxy) -> some View {
    HStack(alignment: .bottom) {
      // comment textfield
      VStack(alignment: .leading) {
        if commentOnEdit != nil {
          HStack {
            Text("Editing", bundle: .module)
              .textCase(.uppercase)
              .font(.footnote)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)

            Spacer()

            Button(String(localized: "Cancel", bundle: .module), systemImage: "xmark") {
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
              logger.error("Failed to write comment: \(error.localizedDescription, privacy: .public)")
              viewModel.alertState = .init(
                title: String(localized: "Unable to write comment.", bundle: .module),
                message: error.localizedDescription
              )
              viewModel.isAlertPresented = true
            }
          }
        }, label: {
          if isUploadingComment {
            ProgressView()
              .tint(.white)
          } else {
            Label(String(localized: "Send", bundle: .module), systemImage: "paperplane")
              .labelStyle(.iconOnly)
              .tint(.white)
          }
        })
        .fontWeight(.medium)
        .padding(12)
        .glassEffect(.regular.tint(Color.accentColor).interactive(), in: .circle)
        .disabled(comment.isEmpty)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .disabled(isUploadingComment)
      }
    }
    .padding(keyboardShowing ? [.horizontal, .vertical] : [.horizontal])
    .contentWidth()
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
    PostAuthorAvatar(url: viewModel.post.myCommentProfile?.profile.profilePictureURL)
  }

  var placeholder: String {
    if let targetComment = targetComment {
      return String(localized: "reply to \(targetComment.author.profile.nickname)", bundle: .module)
    }

    if let commentOnEdit = commentOnEdit {
      return commentOnEdit.content ?? ""
    }

    return String(localized: "reply as \(viewModel.post.myCommentProfile?.profile.nickname ?? "anonymous")", bundle: .module)
  }

  var title: AttributedString {
    var result = AttributedString()

    if let topicName = viewModel.post.topic?.name.localized() {
      var topicAttr = AttributedString("[\(topicName)] ")
      topicAttr.font = .headline
      topicAttr.foregroundColor = .accentColor
      result.append(topicAttr)
    }

    var titleAttr = AttributedString(viewModel.post.title ?? String(localized: "Untitled", bundle: .module))
    titleAttr.font = .headline
    titleAttr.foregroundColor = .primary
    result.append(titleAttr)

    return result
  }

  private func report(type: AraContentReportType) async {
    do {
      try await viewModel.report(type: type)
      viewModel.alertState = .init(
        title: String(localized: "Report Submitted", bundle: .module),
        message: String(localized: "Your report has been submitted successfully.", bundle: .module)
      )
      viewModel.isAlertPresented = true
    } catch {
      logger.error("Failed to submit report: \(error.localizedDescription, privacy: .public)")
      viewModel.alertState = .init(
        title: String(localized: "Unable to submit report.", bundle: .module),
        message: error.localizedDescription
      )
      viewModel.isAlertPresented = true
    }
  }
}

#Preview("Loaded") {
  NavigationStack {
    PostView(post: AraPost.mock, onPostDeleted: nil)
  }
}

#Preview("Loading Content") {
  NavigationStack {
    PostView(post: AraPost.mockList[0], onPostDeleted: nil)
  }
}

#Preview("No Comments") {
  NavigationStack {
    PostView(post: .mockWithoutComments, onPostDeleted: nil)
  }
}

