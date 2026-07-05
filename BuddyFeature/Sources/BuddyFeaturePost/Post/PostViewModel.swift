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
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostViewModel")

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
  var isFoundationModelsAvailable: Bool { get }
  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

  func makePostRequest() -> URLRequest?
  func fetchPost() async
  func upvote() async
  func downvote() async
  func writeComment(content: String) async throws -> AraPostComment
  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment
  func editComment(commentID: Int, content: String) async throws -> AraPostComment
  func report(type: AraContentReportType) async throws
  func summarisedContent() async -> String
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
    didSet { syncHotState() }
  }
  private(set) var upvotes: Int = 0
  private(set) var downvotes: Int = 0
  private(set) var myVote: Bool? = nil
  private(set) var myScrap: Bool = false
  var commentCount: Int = 0
  var comments: [AraPostComment] = []
  var isFoundationModelsAvailable: Bool = false
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

  func makePostRequest() -> URLRequest? {
    guard let url = Constants.araPostFrameURL(postID: post.id),
          let token = araBoardUseCase?.getAccessToken() else {
      return nil
    }
    var request = URLRequest(url: url)
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
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

  func summarisedContent() async -> String {
    guard let foundationModelsUseCase else { return "" }

    analyticsService?.logEvent(PostViewEvent.summariseRequested)
    return await foundationModelsUseCase.summarise(post.content ?? "", maxWords: 50, tone: "concise")
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

