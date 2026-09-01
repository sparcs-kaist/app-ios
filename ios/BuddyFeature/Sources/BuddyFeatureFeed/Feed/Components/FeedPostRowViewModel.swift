//
//  FeedPostRowViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import BuddyFeedCore
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "FeedPostRowViewModel")

@MainActor
@Observable
final class FeedPostRowViewModel: FeedPostRowViewModelProtocol {
  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.feedPostUseCase) private var feedPostUseCase: FeedPostUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Functions
  func upvote(post: Binding<FeedPost>) async {
    await vote(
      post: post,
      type: .up,
      event: .postUpvoted,
      failureTitle: String(localized: "Failed to upvote", bundle: .module)
    )
  }

  func downvote(post: Binding<FeedPost>) async {
    await vote(
      post: post,
      type: .down,
      event: .postDownvoted,
      failureTitle: String(localized: "Failed to downvote", bundle: .module)
    )
  }

  /// Optimistically applies (or toggles off) a vote of `type`, reverting to the
  /// pre-mutation snapshot if the remote call fails.
  private func vote(
    post: Binding<FeedPost>,
    type: FeedVoteType,
    event: FeedPostRowEvent,
    failureTitle: String
  ) async {
    guard let feedPostUseCase else { return }

    let snapshot: FeedPost = post.wrappedValue
    let transition = snapshot.togglingVote(type)

    do {
      post.wrappedValue = transition.post
      switch transition.request {
      case .delete:
        try await feedPostUseCase.deleteVote(postID: snapshot.id)
      case .set(let voteType):
        try await feedPostUseCase.vote(postID: snapshot.id, type: voteType)
      }
      analyticsService?.logEvent(event)
    } catch {
      logger.error("Vote failed: \(error.localizedDescription, privacy: .public)")
      post.wrappedValue = snapshot
      alertState = .init(title: failureTitle, message: error.localizedDescription)
      isAlertPresented = true
    }
  }

  func reportPost(postID: String, reason: FeedReportType) async {
    guard let feedPostUseCase else { return }

    do {
      try await feedPostUseCase.reportPost(postID: postID, reason: reason, detail: "")
      analyticsService?.logEvent(FeedPostRowEvent.postReported(reason: reason.description))
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
