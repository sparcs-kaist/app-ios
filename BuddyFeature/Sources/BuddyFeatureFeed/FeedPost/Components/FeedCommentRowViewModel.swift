//
//  FeedCommentRowViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
protocol FeedCommentRowViewModelProtocol: Observable {
  var alertState: AlertState? { get }
  var isAlertPresented: Bool { get set }

  func upvote(comment: Binding<FeedComment>) async
  func downvote(comment: Binding<FeedComment>) async
  func delete(comment: Binding<FeedComment>) async
  func reportComment(commentID: String, reason: FeedReportType) async
}

@MainActor
@Observable
final class FeedCommentRowViewModel: FeedCommentRowViewModelProtocol {
  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.feedCommentUseCase
  ) private var feedCommentUseCase: FeedCommentUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Functions
  func upvote(comment: Binding<FeedComment>) async {
    guard let feedCommentUseCase else { return }

    let previousMyVote: FeedVoteType? = comment.wrappedValue.myVote
    let previousUpvotes: Int = comment.wrappedValue.upvotes
    let previousDownvotes: Int = comment.wrappedValue.downvotes

    do {
      if previousMyVote == .up {
        // cancel upvote
        comment.wrappedValue.myVote = nil
        comment.wrappedValue.upvotes -= 1
        try await feedCommentUseCase.deleteVote(commentID: comment.wrappedValue.id)
      } else {
        // upvote
        if previousMyVote == .down {
          comment.wrappedValue.downvotes -= 1
        }
        comment.wrappedValue.myVote = .up
        comment.wrappedValue.upvotes += 1
        try await feedCommentUseCase.vote(commentID: comment.wrappedValue.id, type: .up)
      }
    } catch {
      comment.wrappedValue.myVote = previousMyVote
      comment.wrappedValue.upvotes = previousUpvotes
      comment.wrappedValue.downvotes = previousDownvotes
      alertState = .init(
        title: String(localized: "Failed to upvote"),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func downvote(comment: Binding<FeedComment>) async {
    guard let feedCommentUseCase else { return }

    let previousMyVote: FeedVoteType? = comment.wrappedValue.myVote
    let previousUpvotes: Int = comment.wrappedValue.upvotes
    let previousDownvotes: Int = comment.wrappedValue.downvotes

    do {
      if previousMyVote == .down {
        // cancel downvote
        comment.wrappedValue.myVote = nil
        comment.wrappedValue.downvotes -= 1
        try await feedCommentUseCase.deleteVote(commentID: comment.wrappedValue.id)
      } else {
        // downvote
        if previousMyVote == .up {
          comment.wrappedValue.upvotes -= 1
        }
        comment.wrappedValue.myVote = .down
        comment.wrappedValue.downvotes += 1
        try await feedCommentUseCase.vote(commentID: comment.wrappedValue.id, type: .down)
      }
    } catch {
      comment.wrappedValue.myVote = previousMyVote
      comment.wrappedValue.upvotes = previousUpvotes
      comment.wrappedValue.downvotes = previousDownvotes
      alertState = .init(
        title: String(localized: "Failed to downvote"),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func delete(comment: Binding<FeedComment>) async {
    guard let feedCommentUseCase else { return }

    comment.wrappedValue.isDeleted = true
    do {
      try await feedCommentUseCase.deleteComment(commentID: comment.wrappedValue.id)
    } catch {
      comment.wrappedValue.isDeleted = false
      alertState = .init(
        title: String(localized: "Unable to delete comment."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func reportComment(commentID: String, reason: FeedReportType) async {
    guard let feedCommentUseCase else { return }

    do {
      try await feedCommentUseCase.reportComment(commentID: commentID, reason: reason, detail: "")
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
}
