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

@MainActor
protocol PostViewModelProtocol: Observable {
  var post: AraPost { get set }
  var isFoundationModelsAvailable: Bool { get }
  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

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
  var post: AraPost
  var isFoundationModelsAvailable: Bool = false
  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false

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
    Task {
      await refreshFoundationModelsAvailability()
    }
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
      presentAlert(
        title: String(localized: "Unable to fetch post."),
        message: error.localizedDescription
      )
    }
  }

  func upvote() async {
    guard let araBoardUseCase else { return }

    let previousMyVote: Bool? = post.myVote
    let previousUpvotes: Int = post.upvotes

    do {
      if previousMyVote == true {
        // cancel upvote
        post.myVote = nil
        post.upvotes -= 1
        try await araBoardUseCase.cancelVote(postID: post.id)
      } else {
        // upvote
        if previousMyVote == false {
          // remove downvote if there was
          post.downvotes -= 1
        }
        post.myVote = true
        post.upvotes += 1
        try await araBoardUseCase.upvotePost(postID: post.id)
      }
      analyticsService?.logEvent(PostViewEvent.postUpvoted)
    } catch {
      post.upvotes = previousUpvotes
      post.myVote = previousMyVote
    }
  }

  func downvote() async {
    guard let araBoardUseCase else { return }

    let previousMyVote: Bool? = post.myVote
    let previousDownvotes: Int = post.downvotes

    do {
      if previousMyVote == false {
        // cancel downvote
        post.myVote = nil
        post.downvotes -= 1
        try await araBoardUseCase.cancelVote(postID: post.id)
      } else {
        // downvote
        if previousMyVote == true {
          // remove upvote if there was
          post.upvotes -= 1
        }
        post.myVote = false
        post.downvotes += 1
        try await araBoardUseCase.downvotePost(postID: post.id)
      }
      analyticsService?.logEvent(PostViewEvent.postDownvoted)
    } catch {
      post.downvotes = previousDownvotes
      post.myVote = previousMyVote
    }
  }

  func writeComment(content: String) async throws -> AraPostComment {
    guard let araCommentUseCase else { throw CommentWriteError.useCaseNotAvailable }

    var comment: AraPostComment = try await araCommentUseCase.writeComment(
      postID: post.id,
      content: content
    )
    comment.isMine = true

    self.post.comments.append(comment)
    self.post.commentCount += 1

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

    var comments: [AraPostComment] = self.post.comments
    _ = insertThreadedComment(into: &comments, comment: comment)

    self.post.comments = comments
    self.post.commentCount += 1

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

    for idx in post.comments.indices {
      if post.comments[idx].id == commentID {
        post.comments[idx].content = content
        return post.comments[idx]
      }
      // scan through threads
      for threadIdx in post.comments[idx].comments.indices {
        if post.comments[idx].comments[threadIdx].id == commentID {
          post.comments[idx].comments[threadIdx].content = content
          return post.comments[idx]
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

    let previousBookmarkStatus: Bool = post.myScrap

    do {
      if previousBookmarkStatus {
        guard let scrapId = post.scrapId else { return }

        post.myScrap = false
        try await araBoardUseCase.removeBookmark(bookmarkID: scrapId)
      } else {
        post.myScrap = true
        try await araBoardUseCase.addBookmark(postID: post.id)
      }
      analyticsService?.logEvent(PostViewEvent.bookmarkToggled(isBookmarked: post.myScrap))
    } catch {
      post.myScrap = previousBookmarkStatus
    }
  }

  // MARK: - Comment Operations
  func upvoteComment(comment: Binding<AraPostComment>) async {
    guard let araCommentUseCase else { return }

    let previousMyVote: Bool? = comment.wrappedValue.myVote
    let previousUpvotes: Int = comment.wrappedValue.upvotes

    do {
      if previousMyVote == true {
        // cancel upvote
        comment.wrappedValue.myVote = nil
        comment.wrappedValue.upvotes -= 1
        try await araCommentUseCase.cancelVote(commentID: comment.wrappedValue.id)
      } else {
        // upvote
        if previousMyVote == false {
          // remove downvote if there was
          comment.wrappedValue.downvotes -= 1
        }
        comment.wrappedValue.myVote = true
        comment.wrappedValue.upvotes += 1
        try await araCommentUseCase.upvoteComment(commentID: comment.wrappedValue.id)
      }
      analyticsService?.logEvent(PostCommentCellEvent.commentUpvoted)
    } catch {
      comment.wrappedValue.upvotes = previousUpvotes
      comment.wrappedValue.myVote = previousMyVote
    }
  }

  func downvoteComment(comment: Binding<AraPostComment>) async {
    guard let araCommentUseCase else { return }

    let previousMyVote: Bool? = comment.wrappedValue.myVote
    let previousDownvotes: Int = comment.wrappedValue.downvotes

    do {
      if previousMyVote == false {
        // cancel downvote
        comment.wrappedValue.myVote = nil
        comment.wrappedValue.downvotes -= 1
        try await araCommentUseCase.cancelVote(commentID: comment.wrappedValue.id)
      } else {
        // downvote
        if previousMyVote == true {
          // remove upvote if there was
          comment.wrappedValue.upvotes -= 1
        }
        comment.wrappedValue.myVote = false
        comment.wrappedValue.downvotes += 1
        try await araCommentUseCase.downvoteComment(commentID: comment.wrappedValue.id)
      }
      analyticsService?.logEvent(PostCommentCellEvent.commentDownvoted)
    } catch {
      comment.wrappedValue.downvotes = previousDownvotes
      comment.wrappedValue.myVote = previousMyVote
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
      comment.wrappedValue.content = previousContent
    }
  }

  func presentAlert(title: String, message: String) {
    alertState = .init(title: title, message: message)
    isAlertPresented = true
  }
}
