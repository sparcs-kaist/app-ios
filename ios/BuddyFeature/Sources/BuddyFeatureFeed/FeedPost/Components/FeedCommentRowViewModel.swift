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
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "FeedCommentRowViewModel")

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
    await vote(comment: comment, type: .up, failureTitle: String(localized: "Failed to upvote", bundle: .module))
  }

  func downvote(comment: Binding<FeedComment>) async {
    await vote(comment: comment, type: .down, failureTitle: String(localized: "Failed to downvote", bundle: .module))
  }

  /// Optimistically applies (or toggles off) a vote of `type`, reverting to the
  /// pre-mutation snapshot if the remote call fails.
  private func vote(
    comment: Binding<FeedComment>,
    type: FeedVoteType,
    failureTitle: String
  ) async {
    guard let feedCommentUseCase else { return }

    let snapshot: FeedComment = comment.wrappedValue

    do {
      if snapshot.myVote == type {
        // Toggle the existing vote off.
        comment.wrappedValue.myVote = nil
        if type == .up { comment.wrappedValue.upvotes -= 1 } else { comment.wrappedValue.downvotes -= 1 }
        try await feedCommentUseCase.deleteVote(commentID: snapshot.id)
      } else {
        // Clear the opposite vote (if any), then apply the new one.
        if snapshot.myVote == .up { comment.wrappedValue.upvotes -= 1 }
        else if snapshot.myVote == .down { comment.wrappedValue.downvotes -= 1 }
        comment.wrappedValue.myVote = type
        if type == .up { comment.wrappedValue.upvotes += 1 } else { comment.wrappedValue.downvotes += 1 }
        try await feedCommentUseCase.vote(commentID: snapshot.id, type: type)
      }
    } catch {
      logger.error("Vote failed: \(error.localizedDescription, privacy: .public)")
      comment.wrappedValue = snapshot
      alertState = .init(title: failureTitle, message: error.localizedDescription)
      isAlertPresented = true
    }
  }

  func delete(comment: Binding<FeedComment>) async {
    guard let feedCommentUseCase else { return }

    comment.wrappedValue.isDeleted = true
    do {
      try await feedCommentUseCase.deleteComment(commentID: comment.wrappedValue.id)
    } catch {
      logger.error("Failed to delete comment: \(error.localizedDescription, privacy: .public)")
      comment.wrappedValue.isDeleted = false
      alertState = .init(
        title: String(localized: "Unable to delete comment.", bundle: .module),
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
        title: String(localized: "Report Submitted", bundle: .module),
        message: String(localized: "Your report has been submitted successfully.", bundle: .module)
      )
      isAlertPresented = true
    } catch {
      logger.error("Failed to submit report: \(error.localizedDescription, privacy: .public)")
      alertState = .init(
        title: String(localized: "Unable to submit report.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }
}
