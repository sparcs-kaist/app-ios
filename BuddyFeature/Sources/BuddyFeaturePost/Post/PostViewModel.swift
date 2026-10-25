//
//  PostViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
@preconcurrency import Translation
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostViewModel")

/// A post's on-device summary. Kept by the view model, so it outlives the views showing it,
/// such as the post column being rebuilt when the device rotates into side-by-side panes.
enum PostSummaryPhase: Equatable {
  /// The summary written so far; empty until the first words arrive.
  case summarising(String)
  case finished(String)
  case failed(message: String)
}

@MainActor
protocol PostViewModelProtocol: Observable {
  var post: AraPost { get set }
  // Hot, independently-mutated state is flattened off `post` so that a vote,
  // bookmark, or comment change invalidates only the view that reads it (the
  // footer / comments section) rather than every view that reads `post`.
  var upvotes: Int { get }
  var downvotes: Int { get }
  var myVote: Bool? { get }
  var myScrap: Bool { get }
  var commentCount: Int { get set }
  var comments: [AraPostComment] { get set }
  /// `nil` until `prepareContentBody()` has parsed the fetched content.
  var contentBody: PostBody? { get }
  var isFoundationModelsAvailable: Bool { get }
  /// Whether the post is shown as written, being translated, or translated in place.
  var translationState: PostTranslationState { get }
  /// Languages the post can be translated into, once loaded.
  var translationLanguages: [Locale.Language] { get }
  /// The language the post is detected to be written in.
  var sourceLanguage: Locale.Language? { get }
  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

  func prepareContentBody() async
  func loadTranslationLanguages() async
  /// Starts translating into `target`; the view runs the session and calls `translate(using:)`.
  func requestTranslation(to target: Locale.Language) -> TranslationSession.Configuration
  func translate(using session: TranslationSession) async
  func showOriginal()
  func fetchPost() async
  func upvote() async
  func downvote() async
  func writeComment(content: String) async throws -> AraPostComment
  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment
  func editComment(commentID: Int, content: String) async throws -> AraPostComment
  func report(type: AraContentReportType) async throws
  /// `nil` until a summary is asked for.
  var summaryPhase: PostSummaryPhase? { get }
  /// Whether the post is long enough to be worth summarising on this device.
  var canSummarise: Bool { get }
  /// Summarises the post, or tries again after a failure. A summary already written or being
  /// written is left alone.
  func summarise()
  func deletePost() async throws
  func toggleBookmark() async

  // Comment operations (moved from PostCommentCell)
  func upvoteComment(comment: Binding<AraPostComment>) async
  func downvoteComment(comment: Binding<AraPostComment>) async
  func reportComment(commentID: Int, type: AraContentReportType) async throws
  func deleteComment(comment: Binding<AraPostComment>) async
}



@Observable
class PostViewModel: PostViewModelProtocol {
  // MARK: - Properties
  /// The full post. Source of truth for static fields (title, author, views,
  /// content, board, topic) and for round-tripping (translation). Reassigned
  /// only on `fetchPost`; hot fields below are mutated in isolation instead.
  var post: AraPost {
    didSet {
      syncHotState()
      if post.content != oldValue.content || post.title != oldValue.title {
        translationState = .original
      }
    }
  }
  private(set) var upvotes: Int = 0
  private(set) var downvotes: Int = 0
  private(set) var myVote: Bool? = nil
  private(set) var myScrap: Bool = false
  var commentCount: Int = 0
  var comments: [AraPostComment] = []
  private(set) var contentBody: PostBody? = nil
  private(set) var translationState: PostTranslationState = .original
  private(set) var translationLanguages: [Locale.Language] = []
  private(set) var sourceLanguage: Locale.Language?
  var isFoundationModelsAvailable: Bool = false
  private(set) var summaryPhase: PostSummaryPhase?
  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false

  /// Copies the hot, view-facing fields off `post`. Called on init and whenever
  /// `post` is replaced wholesale (e.g. after `fetchPost`).
  private func syncHotState() {
    upvotes = post.upvotes
    downvotes = post.downvotes
    myVote = post.myVote
    myScrap = post.myScrap
    commentCount = post.commentCount
    comments = post.comments
  }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.araCommentUseCase
  ) private var araCommentUseCase: AraCommentUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.foundationModelsUseCase
  ) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  enum CommentWriteError: Error {
    case useCaseNotAvailable
  }

  // MARK: - Initialiser
  init(post: AraPost) {
    self.post = post
    syncHotState()

    Task {
      await refreshFoundationModelsAvailability()
    }
  }

  /// Parses `post.content` off the main actor. The previous body stays on screen until the new
  /// one is ready, so a refresh doesn't flash a spinner.
  func prepareContentBody() async {
    // A post opened from a list has no content until `fetchPost` returns.
    guard let content = post.content else { return }
    let boardSlug = post.board?.slug
    let body = await Task.detached(priority: .userInitiated) {
      PostBody.make(from: content, boardSlug: boardSlug)
    }.value
    guard !Task.isCancelled else { return }
    contentBody = body
  }

  // MARK: - Translation

  func loadTranslationLanguages() async {
    // The language is detected from the content, which a post opened from a list doesn't have yet.
    guard translationLanguages.isEmpty, post.content != nil else { return }
    sourceLanguage = PostTranslator.dominantLanguage(of: "\(post.title ?? "")\n\(post.contentPlainText)")
    let supported = await LanguageAvailability().supportedLanguages
    translationLanguages = PostTranslator.targetLanguages(from: supported, excluding: sourceLanguage)
  }

  func requestTranslation(to target: Locale.Language) -> TranslationSession.Configuration {
    translationState = .translating(to: target)
    analyticsService?.logEvent(PostViewEvent.translationRequested(target: target.minimalIdentifier))
    // A known source spares the system from asking which language the post is in.
    return TranslationSession.Configuration(source: sourceLanguage, target: target)
  }

  func translate(using session: TranslationSession) async {
    guard case .translating(let target) = translationState else { return }
    do {
      let translation = try await PostTranslator.translate(
        post: post,
        document: PostTranslator.document(for: post),
        using: session,
        source: sourceLanguage,
        target: target
      )
      // The reader may have picked another language, or the original, in the meantime.
      guard translationState == .translating(to: target) else { return }
      translationState = .translated(translation)
    } catch {
      guard translationState == .translating(to: target) else { return }
      translationState = .original
      // Closing the system's language download sheet cancels; that needs no alert.
      if error is CancellationError || Task.isCancelled { return }
      logger.error("Failed to translate post: \(error.localizedDescription, privacy: .public)")
      presentAlert(
        title: String(localized: "Unable to translate post.", bundle: .module),
        message: error.localizedDescription
      )
    }
  }

  func showOriginal() {
    translationState = .original
  }

  private func refreshFoundationModelsAvailability() async {
    guard let foundationModelsUseCase else { return }

    isFoundationModelsAvailable = await foundationModelsUseCase.isAvailable()
  }

  private func insertThreadedComment(into comments: inout [AraPostComment], comment: AraPostComment) -> Bool {
    for idx in comments.indices {
      guard let parentComment = comment.parentComment else {
        return false
      }

      if comments[idx].id == parentComment {
        comments[idx].comments.append(comment)

        return true
      }
    }

    return false
  }

  // MARK: - Functions
  func fetchPost() async {
    guard let araBoardUseCase else { return }

    do {
      let post: AraPost = try await araBoardUseCase.fetchPost(origin: .board, postID: post.id)
      self.post = post
    } catch {
      logger.error("Failed to fetch post: \(error.localizedDescription, privacy: .public)")
      presentAlert(
        title: String(localized: "Unable to fetch post.", bundle: .module),
        message: error.localizedDescription
      )
    }
  }

  func upvote() async {
    await vote(isUpvote: true, event: .postUpvoted)
  }

  func downvote() async {
    await vote(isUpvote: false, event: .postDownvoted)
  }

  /// Optimistically applies (or toggles off) a vote, reverting to the
  /// pre-mutation snapshot if the remote call fails. `myVote` is `true` for an
  /// upvote and `false` for a downvote.
  private func vote(isUpvote: Bool, event: PostViewEvent) async {
    guard let araBoardUseCase else { return }

    // Snapshot only the vote-related hot fields, so a revert doesn't disturb
    // (and re-invalidate) anything else.
    let previousMyVote: Bool? = myVote
    let previousUpvotes: Int = upvotes
    let previousDownvotes: Int = downvotes

    do {
      if myVote == isUpvote {
        // Toggle the existing vote off.
        myVote = nil
        if isUpvote { upvotes -= 1 } else { downvotes -= 1 }
        try await araBoardUseCase.cancelVote(postID: post.id)
      } else {
        // Clear the opposite vote (if any), then apply the new one.
        if myVote == true { upvotes -= 1 }
        else if myVote == false { downvotes -= 1 }
        myVote = isUpvote
        if isUpvote { upvotes += 1 } else { downvotes += 1 }
        if isUpvote {
          try await araBoardUseCase.upvotePost(postID: post.id)
        } else {
          try await araBoardUseCase.downvotePost(postID: post.id)
        }
      }
      analyticsService?.logEvent(event)
    } catch {
      logger.error("Vote failed: \(error.localizedDescription, privacy: .public)")
      myVote = previousMyVote
      upvotes = previousUpvotes
      downvotes = previousDownvotes
    }
  }

  func writeComment(content: String) async throws -> AraPostComment {
    guard let araCommentUseCase else { throw CommentWriteError.useCaseNotAvailable }

    var comment: AraPostComment = try await araCommentUseCase.writeComment(
      postID: post.id,
      content: content
    )
    comment.isMine = true

    self.comments.append(comment)
    self.commentCount += 1

    analyticsService?.logEvent(PostViewEvent.commentSubmitted)

    return comment
  }

  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    guard let araCommentUseCase else { throw CommentWriteError.useCaseNotAvailable }
    var comment: AraPostComment = try await araCommentUseCase.writeThreadedComment(
      commentID: commentID,
      content: content
    )
    comment.isMine = true

    // insert threaded comments

    var comments: [AraPostComment] = self.comments
    _ = insertThreadedComment(into: &comments, comment: comment)

    self.comments = comments
    self.commentCount += 1

    analyticsService?.logEvent(PostViewEvent.commentSubmitted)

    return comment
  }

  func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    guard let araCommentUseCase else { throw CommentWriteError.useCaseNotAvailable }

    var comment: AraPostComment = try await araCommentUseCase.editComment(
      commentID: commentID,
      content: content
    )
    comment.isMine = true

    for idx in comments.indices {
      if comments[idx].id == commentID {
        comments[idx].content = content
        return comments[idx]
      }
      // scan through threads
      for threadIdx in comments[idx].comments.indices {
        if comments[idx].comments[threadIdx].id == commentID {
          comments[idx].comments[threadIdx].content = content
          return comments[idx]
        }
      }
    }

    return comment
  }

  func report(type: AraContentReportType) async throws {
    guard let araBoardUseCase else { return }

    try await araBoardUseCase.reportPost(postID: post.id, type: type)
    analyticsService?.logEvent(PostViewEvent.postReported(type: "\(type)"))
  }

  /// Shorter posts are quicker to read than a summary of them, as with reviews.
  static let minimumSummaryLength = 200

  var canSummarise: Bool {
    guard isFoundationModelsAvailable, let contentBody else { return false }
    return contentBody.textLength >= Self.minimumSummaryLength
  }

  func summarise() {
    guard let foundationModelsUseCase, canSummarise else { return }
    switch summaryPhase {
    case .summarising, .finished: return
    case .failed, nil: break
    }

    summaryPhase = .summarising("")
    analyticsService?.logEvent(PostViewEvent.summaryRequested)
    let text = post.contentPlainText

    Task {
      var summary = ""
      do {
        // Shown as it's written, as review summaries are.
        for try await snapshot in await foundationModelsUseCase.streamSummary(of: text, as: .post) {
          summary = snapshot
          summaryPhase = .summarising(snapshot)
        }
        summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else { throw SummarisationError.failed }
        summaryPhase = .finished(summary)
        analyticsService?.logEvent(PostViewEvent.summaryFinished)
      } catch {
        let reason = error as? SummarisationError ?? .failed
        summaryPhase = .failed(message: reason.localizedDescription)
        analyticsService?.logEvent(PostViewEvent.summaryFailed(reason: reason))
      }
    }
  }

  func deletePost() async throws {
    guard let araBoardUseCase else { return }

    try await araBoardUseCase.deletePost(postID: post.id)
    analyticsService?.logEvent(PostViewEvent.postDeleted)
  }

  func toggleBookmark() async {
    guard let araBoardUseCase else { return }

    let previousBookmarkStatus: Bool = myScrap

    do {
      if previousBookmarkStatus {
        guard let scrapId = post.scrapId else { return }

        myScrap = false
        try await araBoardUseCase.removeBookmark(bookmarkID: scrapId)
      } else {
        myScrap = true
        try await araBoardUseCase.addBookmark(postID: post.id)
      }
      analyticsService?.logEvent(PostViewEvent.bookmarkToggled(isBookmarked: myScrap))
    } catch {
      logger.error("Failed to toggle bookmark: \(error.localizedDescription, privacy: .public)")
      myScrap = previousBookmarkStatus
    }
  }

  // MARK: - Comment Operations
  func upvoteComment(comment: Binding<AraPostComment>) async {
    await voteComment(comment: comment, isUpvote: true, event: .commentUpvoted)
  }

  func downvoteComment(comment: Binding<AraPostComment>) async {
    await voteComment(comment: comment, isUpvote: false, event: .commentDownvoted)
  }

  /// Optimistically applies (or toggles off) a comment vote, reverting to the
  /// pre-mutation snapshot if the remote call fails.
  private func voteComment(
    comment: Binding<AraPostComment>,
    isUpvote: Bool,
    event: PostCommentCellEvent
  ) async {
    guard let araCommentUseCase else { return }

    let snapshot: AraPostComment = comment.wrappedValue

    do {
      if comment.wrappedValue.myVote == isUpvote {
        // Toggle the existing vote off.
        comment.wrappedValue.myVote = nil
        if isUpvote { comment.wrappedValue.upvotes -= 1 } else { comment.wrappedValue.downvotes -= 1 }
        try await araCommentUseCase.cancelVote(commentID: snapshot.id)
      } else {
        // Clear the opposite vote (if any), then apply the new one.
        if comment.wrappedValue.myVote == true { comment.wrappedValue.upvotes -= 1 }
        else if comment.wrappedValue.myVote == false { comment.wrappedValue.downvotes -= 1 }
        comment.wrappedValue.myVote = isUpvote
        if isUpvote { comment.wrappedValue.upvotes += 1 } else { comment.wrappedValue.downvotes += 1 }
        if isUpvote {
          try await araCommentUseCase.upvoteComment(commentID: snapshot.id)
        } else {
          try await araCommentUseCase.downvoteComment(commentID: snapshot.id)
        }
      }
      analyticsService?.logEvent(event)
    } catch {
      logger.error("Comment vote failed: \(error.localizedDescription, privacy: .public)")
      comment.wrappedValue = snapshot
    }
  }

  func reportComment(commentID: Int, type: AraContentReportType) async throws {
    guard let araCommentUseCase else { return }

    try await araCommentUseCase.reportComment(commentID: commentID, type: type)
    analyticsService?.logEvent(PostCommentCellEvent.commentReported(type: "\(type)"))
  }

  func deleteComment(comment: Binding<AraPostComment>) async {
    guard let araCommentUseCase else { return }

    let previousContent: String? = comment.wrappedValue.content
    do {
      comment.wrappedValue.content = nil
      try await araCommentUseCase.deleteComment(commentID: comment.wrappedValue.id)
      analyticsService?.logEvent(PostCommentCellEvent.commentDeleted)
    } catch {
      logger.error("Failed to delete comment: \(error.localizedDescription, privacy: .public)")
      comment.wrappedValue.content = previousContent
    }
  }

  func presentAlert(title: String, message: String) {
    alertState = .init(title: title, message: message)
    isAlertPresented = true
  }
}

