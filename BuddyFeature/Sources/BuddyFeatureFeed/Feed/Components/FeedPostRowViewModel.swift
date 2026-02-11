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
    guard let feedPostUseCase else { return }

    let previousMyVote: FeedVoteType? = post.wrappedValue.myVote
    let previousUpvotes: Int = post.wrappedValue.upvotes
    let previousDownvotes: Int = post.wrappedValue.downvotes

    do {
      if previousMyVote == .up {
        // cancel upvote
        post.wrappedValue.myVote = nil
        post.wrappedValue.upvotes -= 1
        try await feedPostUseCase.deleteVote(postID: post.wrappedValue.id)
      } else {
        // upvote
        if previousMyVote == .down {
          post.wrappedValue.downvotes -= 1
        }
        post.wrappedValue.myVote = .up
        post.wrappedValue.upvotes += 1
        try await feedPostUseCase.vote(postID: post.wrappedValue.id, type: .up)
      }
      analyticsService?.logEvent(FeedPostRowEvent.postUpvoted)
    } catch {
      post.wrappedValue.myVote = previousMyVote
      post.wrappedValue.upvotes = previousUpvotes
      post.wrappedValue.downvotes = previousDownvotes
      alertState = .init(
        title: String(localized: "Failed to upvote"),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func downvote(post: Binding<FeedPost>) async {
    guard let feedPostUseCase else { return }

    let previousMyVote: FeedVoteType? = post.wrappedValue.myVote
    let previousUpvotes: Int = post.wrappedValue.upvotes
    let previousDownvotes: Int = post.wrappedValue.downvotes

    do {
      if previousMyVote == .down {
        // cancel downvote
        post.wrappedValue.myVote = nil
        post.wrappedValue.downvotes -= 1
        try await feedPostUseCase.deleteVote(postID: post.wrappedValue.id)
      } else {
        // downvote
        if previousMyVote == .up {
          post.wrappedValue.upvotes -= 1
        }
        post.wrappedValue.myVote = .down
        post.wrappedValue.downvotes += 1
        try await feedPostUseCase.vote(postID: post.wrappedValue.id, type: .down)
      }
      analyticsService?.logEvent(FeedPostRowEvent.postDownvoted)
    } catch {
      post.wrappedValue.myVote = previousMyVote
      post.wrappedValue.upvotes = previousUpvotes
      post.wrappedValue.downvotes = previousDownvotes
      alertState = .init(
        title: String(localized: "Failed to downvote"),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func reportPost(postID: String, reason: FeedReportType) async {
    guard let feedPostUseCase else { return }

    do {
      try await feedPostUseCase.reportPost(postID: postID, reason: reason, detail: "")
      analyticsService?.logEvent(FeedPostRowEvent.postReported(reason: reason.description))
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
