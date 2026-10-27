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
import TipKit
@preconcurrency import Translation
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostView")

public struct PostView: View {
  @State private var viewModel: PostViewModelProtocol
  @Environment(\.dismiss) private var dismiss

  @Environment(\.keyboardShowing) var keyboardShowing
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @State private var viewport: CGSize = .zero

  @State private var tappedURL: URL?

  @State private var comment: String = ""
  @FocusState private var isWritingCommentFocusState: Bool
  @State private var isWritingComment: Bool = false
  @State private var targetComment: AraPostComment? = nil
  @State private var commentOnEdit: AraPostComment? = nil
  @State private var isUploadingComment: Bool = false

  /// The comment to pin to the top while a reply to it is being written.
  private var replyScrollTargetID: Int? {
    isWritingCommentFocusState ? targetComment?.id : nil
  }

  @State private var selectedAuthor: AraPostAuthor? = nil

  @State private var translationConfiguration: TranslationSession.Configuration?
  @State private var showDeleteConfirmation: Bool = false
  @State private var showBlockConfirmation: Bool = false
  @State private var showEditView: Bool = false

  @State private var showsToolsTip = false

  let onPostDeleted: ((Int) -> Void)?

  public init(post: AraPost, onPostDeleted: ((Int) -> Void)? = nil) {
    _viewModel = State(initialValue: PostViewModel(post: post))
    self.onPostDeleted = onPostDeleted
  }

  public var body: some View {
    ScrollViewReader { proxy in
      Group {
        if usesPanes {
          PostPanes {
            column { postSection(proxy: proxy) }
          } comments: {
            column { commentsSection }
              .safeAreaBar(edge: .bottom) {
                inputBar(proxy: proxy)
              }
          }
        } else {
          column {
            postSection(proxy: proxy)
            commentsSection
          }
        }
      }
      .onGeometryChange(for: CGSize.self) { $0.size } action: { viewport = $0 }
      .onChange(of: replyScrollTargetID) { _, id in
        guard let id else { return }
        // Wait a turn so the bottom spacer is laid out before scrolling.
        Task { @MainActor in
          withAnimation(.spring) {
            proxy.scrollTo(id, anchor: .top)
          }
        }
      }
      .modifier(PinnedNavigationBar(isPinned: usesPanes))
      .scrollDismissesKeyboard(.immediately)
      .onKeyboardDismiss {
        if comment.isEmpty {
          targetComment = nil
        }
      }
      .contentMargins(.bottom, 64)
      .navigationTitle(viewModel.post.board?.name.localized() ?? "")
      // Its own, rather than whatever the screen it was opened from uses (the Boards list's is large).
      .navigationBarTitleDisplayMode(.inline)
      .safeAreaBar(edge: .bottom) {
        // Side by side, it belongs to the comments pane.
        if !usesPanes {
          inputBar(proxy: proxy)
        }
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
            .confirmationDialog(
              String(localized: "Block \(viewModel.post.author.profile.nickname)?", bundle: .module),
              isPresented: $showBlockConfirmation,
              titleVisibility: .visible
            ) {
              Button(String(localized: "Block", bundle: .module), role: .destructive) {
                Task { await viewModel.setAuthorBlocked(viewModel.post.author, blocked: true) }
              }
              Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
            } message: {
              Text("You won't see their posts or comments on Ara. You can unblock them from the same menu.", bundle: .module)
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
      .sheet(isPresented: $showEditView) {
        if let board = viewModel.post.board {
          PostComposeView(editing: viewModel.post, board: board) {
            Task { await viewModel.fetchPost() }
          }
        }
      }
      .translationTask(translationConfiguration) { session in
        await viewModel.translate(using: session)
      }
      .navigationDestination(item: $selectedAuthor) { author in
        UserPostListView(user: author)
      }
      .task {
        await viewModel.fetchPost()
      }
      .task(id: viewModel.post.id) {
        await PostToolsTip.postOpened.donate()
      }
      .task(id: viewModel.post.content) {
        await viewModel.prepareContentBody()
        await viewModel.loadTranslationLanguages()
        let content = if case .tiptap(_, let plainText) = viewModel.contentBody {
          plainText
        } else {
          viewModel.post.content ?? ""
        }
        showsToolsTip = await Task.detached { PostToolsTip.isWorthShowing(for: content) }.value
      }
      .refreshable {
        await viewModel.fetchPost()
      }
    }
    .analyticsScreen(name: "Ara Post", class: String(describing: Self.self), extraParameters: [
      "is_author": viewModel.post.isMine ?? false,
      "has_comments": viewModel.commentCount > 0
    ])
  }

  // MARK: - Layout

  /// A summary written or being written; after a failure, the post's own Try Again asks again.
  private var isSummaryShown: Bool {
    switch viewModel.summaryPhase {
    case .summarising, .finished: true
    case .failed, nil: false
    }
  }

  /// Post on the left, comments on the right, when there's room for both side by side: iPad and
  /// the inner display of iPhone Duo, wider than tall. Max iPhones in landscape are regular width
  /// but compact height, and keep the single column.
  private var usesPanes: Bool {
    horizontalSizeClass == .regular
      && verticalSizeClass == .regular
      && viewport.width > viewport.height
      && viewport.width >= PostPaneWidth.post + PostPaneWidth.comments
  }

  private func column(@ViewBuilder content: () -> some View) -> some View {
    PostColumn(summaryPhase: viewModel.summaryPhase, translationState: viewModel.translationState, content: content)
  }

  private func postSection(proxy: ScrollViewProxy) -> some View {
    PostSection(
      viewModel: viewModel,
      title: title,
      content: displayedContent,
      isTranslating: isTranslating,
      showsToolsTip: showsToolsTip,
      onAuthorTapped: { selectedAuthor = viewModel.post.author },
      onLinkTapped: { tappedURL = $0 },
      onScrollToImage: { proxy.scrollTo($0, anchor: .center) },
      onCommentTapped: {
        targetComment = nil
        isWritingCommentFocusState = true
      }
    )
  }

  @ViewBuilder
  private var commentsSection: some View {
    PostComments(
      viewModel: viewModel,
      comments: $viewModel.comments,
      showsTopDivider: !usesPanes,
      onReply: { selectedComment in
        // A reply replaces an edit in progress rather than sending as one.
        if commentOnEdit != nil {
          comment = ""
          commentOnEdit = nil
        }
        targetComment = selectedComment
        isWritingCommentFocusState = true
      },
      onEdit: { selectedComment in
        withAnimation(.spring) {
          comment = selectedComment.content ?? ""
          targetComment = nil
          commentOnEdit = selectedComment
        }
        isWritingCommentFocusState = true
      },
      onCommentDeleted: {
        viewModel.commentCount -= 1
      }
    )

    // Comments near the end of the list have too little content below them to reach the top,
    // so pad the bottom by a screen's height while replying. Sized in layout, so no state
    // updates during the keyboard animation.
    if replyScrollTargetID != nil {
      Color.clear
        .containerRelativeFrame(.vertical)
    }
  }

  /// Whether the app can load this post into its editor: Tiptap posts, and the simple HTML
  /// earlier versions of the app wrote. A post that hasn't loaded its content can't be edited.
  private var canEdit: Bool {
    guard viewModel.post.board != nil, let content = viewModel.post.content else { return false }
    return PostEditableContent.document(from: content) != nil
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

      // Only authors named by their nickname can be blocked.
      if viewModel.post.isMine == false, viewModel.post.author.blockableUserID != nil {
        if viewModel.post.author.isBlocked == true {
          Button(String(localized: "Unblock Author", bundle: .module), systemImage: "person.crop.circle.badge.checkmark") {
            Task { await viewModel.setAuthorBlocked(viewModel.post.author, blocked: false) }
          }
        } else {
          Button(String(localized: "Block Author", bundle: .module), systemImage: "person.crop.circle.badge.xmark", role: .destructive) {
            showBlockConfirmation = true
          }
        }
      }

      if viewModel.post.isMine == false { Divider () }

      translateMenu

      if viewModel.canSummarise {
        Button(String(localized: "Summarise", bundle: .module), systemImage: "text.append") {
          PostToolsTip().invalidate(reason: .actionPerformed)
          Haptic.start.generate()
          viewModel.summarise()
        }
        .disabled(isSummaryShown)
      }

      if viewModel.post.isMine == true { Divider () }

      if viewModel.post.isMine == true, canEdit {
        Button(String(localized: "Edit", bundle: .module), systemImage: "pencil") {
          showEditView = true
        }
      }

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
        if let targetComment {
          CommentReplyPreview(
            authorName: targetComment.author.profile.nickname,
            content: targetComment.content ?? "",
            isDeleted: targetComment.content == nil,
            onCancel: { self.targetComment = nil }
          )
          // The bar's own tint is primary, for the cursor; this matches Ara's red background.
          .tint(.red)
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }

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
            // Without a cap a long comment grows the bar over the post, which on a short screen
            // such as the outer display of iPhone Duo leaves almost nothing of the post visible.
            .lineLimit(1...5)
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
        // Red, like the reply preview and Ara's background.
        .glassEffect(.regular.tint(.red).interactive(), in: .circle)
        .disabled(comment.isEmpty)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .disabled(isUploadingComment)
      }
    }
    .padding(keyboardShowing ? [.horizontal, .vertical] : [.horizontal])
    .contentWidth()
    // The capped bar is centred, so half-folded on iPhone Duo it would straddle the hinge.
    .avoidingFold()
    .animation(.spring, value: keyboardShowing)
    .animation(.spring, value: targetComment?.id)
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

  // MARK: - Translation

  private var isTranslating: Bool {
    if case .translating = viewModel.translationState { true } else { false }
  }

  private var translatedTitle: String? {
    if case .translated(let translation) = viewModel.translationState { translation.title } else { nil }
  }

  /// The body as written, or translated in place with its structure kept.
  private var displayedContent: PostBody? {
    if case .translated(let translation) = viewModel.translationState {
      return .tiptap(translation.layout, plainText: "")
    }
    return viewModel.contentBody
  }

  private var translateMenu: some View {
    Menu(String(localized: "Translate", bundle: .module), systemImage: "translate") {
      if viewModel.translationState != .original {
        Button(String(localized: "Show Original", bundle: .module), systemImage: "arrow.uturn.backward") {
          viewModel.showOriginal()
        }
      }

      Picker(selection: Binding(
        get: { viewModel.translationState.target },
        set: { target in
          if let target { translate(to: target) }
        }
      )) {
        ForEach(viewModel.translationLanguages, id: \.minimalIdentifier) { language in
          Text(PostTranslator.displayName(for: language))
            .tag(Optional(language))
        }
      } label: {
        Text("Translate to", bundle: .module)
      }
      .pickerStyle(.inline)
    }
    .disabled(viewModel.translationLanguages.isEmpty)
  }

  private func translate(to target: Locale.Language) {
    PostToolsTip().invalidate(reason: .actionPerformed)
    let configuration = viewModel.requestTranslation(to: target)
    // An unchanged configuration doesn't re-run the task; invalidating it does.
    if translationConfiguration == configuration {
      translationConfiguration?.invalidate()
    } else {
      translationConfiguration = configuration
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

    // A hidden post has no title, so say why it's hidden instead.
    let plainTitle = viewModel.post.isHidden
      ? viewModel.post.listTitle
      : translatedTitle ?? viewModel.post.title ?? String(localized: "Untitled", bundle: .module)
    var titleAttr = AttributedString(plainTitle)
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
