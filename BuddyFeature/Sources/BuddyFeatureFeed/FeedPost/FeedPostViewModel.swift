//
//  FeedPostViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 24/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
protocol FeedPostViewModelProtocol: Observable {
  var state: FeedPostViewModel.ViewState { get }
  var comments: [FeedComment] { get set }
  var text: String { get set }
  var image: UIImage? { get set }
  var isAnonymous: Bool { get set }

  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }
  var isSubmittingComment: Bool { get }
  var feedUser: FeedUser? { get }

  func fetchComments(postID: String, initial: Bool) async
  func writeComment(postID: String) async throws -> FeedComment
  func writeReply(commentID: String) async throws -> FeedComment
  func reportPost(postID: String, reason: FeedReportType) async
  func submitComment(postID: String, replyingTo targetComment: FeedComment?) async -> FeedComment?
  func fetchFeedUser() async
}

@Observable
class FeedPostViewModel: FeedPostViewModelProtocol {
  enum ViewState: Comparable {
    case loading
    case loaded
    case error(message: String)
  }

  enum CommentWriteError: Error {
    case repositoryNotAvailable
  }

  // MARK: - Properties
  var state: ViewState = .loading
  var comments: [FeedComment] = []

  var text: String = ""
  var image: UIImage? = nil
  var isAnonymous: Bool = true

  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false
  var isSubmittingComment: Bool = false
  var feedUser: FeedUser? = nil

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.feedCommentUseCase
  ) private var feedCommentUseCase: FeedCommentUseCaseProtocol?
  @ObservationIgnored @Injected(\.feedPostUseCase) private var feedPostUseCase: FeedPostUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Functions
  func fetchComments(postID: String, initial: Bool) async {
    guard state != .loading || initial else { return }
    guard let feedCommentUseCase else { return }

    do {
      let comments: [FeedComment] = try await feedCommentUseCase.fetchComments(postID: postID)
      self.comments = comments
      self.state = .loaded
      if !initial {
        analyticsService?.logEvent(FeedPostViewEvent.commentsRefreshed)
      }
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }

  func writeComment(postID: String) async throws -> FeedComment {
    guard let feedCommentUseCase else { throw CommentWriteError.repositoryNotAvailable }

    let request = FeedCreateComment(
      content: text,
      isAnonymous: isAnonymous,
      image: nil
    )
    let comment: FeedComment = try await feedCommentUseCase.writeComment(postID: postID, request: request)

    self.comments.append(comment)

    return comment
  }

  private func insertReply(into comments: inout [FeedComment], comment: FeedComment) -> Bool {
    for idx in comments.indices {
      guard let parentCommentID = comment.parentCommentID else {
        return false
      }

      if comments[idx].id == parentCommentID {
        comments[idx].replies.append(comment)

        return true
      }
    }

    return false
  }

  func writeReply(commentID: String) async throws -> FeedComment {
    guard let feedCommentUseCase else { throw CommentWriteError.repositoryNotAvailable }

    let request = FeedCreateComment(content: text, isAnonymous: isAnonymous, image: nil)
    let comment: FeedComment = try await feedCommentUseCase.writeReply(commentID: commentID, request: request)

    var comments: [FeedComment] = self.comments
    _ = insertReply(into: &comments, comment: comment)
    self.comments = comments

    return comment
  }

  func reportPost(postID: String, reason: FeedReportType) async {
    guard let feedPostUseCase else { return }

    do {
      try await feedPostUseCase.reportPost(postID: postID, reason: reason, detail: "")
      analyticsService?.logEvent(FeedPostViewEvent.postReported(reason: reason.description))
      alertState = .init(
        title: String(localized: "Report Submitted"),
        message: String(localized: "Your report has been submitted successfully.")
      )
      isAlertPresented = true
    } catch {
      alertState = .init(
        title: String(localized: "Unable to submit report."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func submitComment(postID: String, replyingTo targetComment: FeedComment?) async -> FeedComment? {
    isSubmittingComment = true
    defer { isSubmittingComment = false }

    do {
      let uploadedComment: FeedComment
      if let targetComment {
        uploadedComment = try await writeReply(commentID: targetComment.id)
      } else {
        uploadedComment = try await writeComment(postID: postID)
      }
      analyticsService?.logEvent(
        FeedPostViewEvent.commentSubmitted(
          isReply: targetComment != nil,
          isAnonymous: isAnonymous
        )
      )
      text = ""
      return uploadedComment
    } catch {
      alertState = .init(
        title: String(localized: "Unable to write comment."),
        message: error.localizedDescription
      )
      isAlertPresented = true
      return nil
    }
  }

  func fetchFeedUser() async {
    guard let userUseCase else { return }
    self.feedUser = await userUseCase.feedUser
  }
}
