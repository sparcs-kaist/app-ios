//
//  ReviewDigestModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation
import Observation
import Factory
import BuddyDomain

/// Summarises a lecture's reviews with the on-device model, for the review
/// sections of the lecture and course screens.
@MainActor
@Observable
final class ReviewDigestModel {
  enum Phase: Equatable {
    case idle
    /// `completed` of `total` batches of reviews have been read; `total` is 0
    /// until the model says how many there are.
    case reading(completed: Int, total: Int)
    case writing(LectureReviewDigest)
    case finished(LectureReviewDigest)
    case failed(message: String)
  }

  /// Fewer reviews than this are quicker to read than their summary.
  static let minimumReviewCount = 3

  private(set) var phase: Phase = .idle
  private(set) var isAvailable = false
  /// How many reviews the digest reads, which for popular lectures is fewer than
  /// they have.
  private(set) var reviewCount = 0
  /// Bumped by `requestSummary(of:)`, so the screen runs the summary again.
  private(set) var attempt = 0

  @ObservationIgnored @Injected(
    \.foundationModelsUseCase
  ) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  /// The reviews the current phase is about.
  @ObservationIgnored private var reviewIDs: [Int] = []
  /// The reviews a summary was last asked for, when summaries aren't automatic.
  @ObservationIgnored private var requestedReviewIDs: [Int]?
  /// The screen the digest is on, for analytics.
  @ObservationIgnored private let source: String

  init(source: String) {
    self.source = source
  }

  /// Whether `reviews` are worth summarising on this device.
  func canSummarise(_ reviews: [LectureReview]) -> Bool {
    isAvailable && Self.readableCount(of: reviews) >= Self.minimumReviewCount
  }

  func checkAvailability() async {
    isAvailable = await foundationModelsUseCase?.isAvailable() ?? false
  }

  /// Summarises `reviews` unless they already have been, or, when summaries
  /// aren't automatic, unless nobody asked. Runs for as long as the calling task
  /// does, so a summary left unfinished by leaving the screen starts again on
  /// coming back rather than running on unseen.
  func summariseIfNeeded(_ reviews: [LectureReview], automatically: Bool) async {
    guard let foundationModelsUseCase, canSummarise(reviews) else { return }
    let ids = reviews.map(\.id)
    guard automatically || requestedReviewIDs == ids else { return }
    switch phase {
    case .finished, .failed:
      if ids == reviewIDs { return }
    case .idle, .reading, .writing:
      break
    }

    reviewIDs = ids
    reviewCount = Self.readableCount(of: reviews)
    phase = .reading(completed: 0, total: 0)
    analyticsService?.logEvent(ReviewDigestEvent.requested(source: source, reviewCount: reviewCount))

    var digest: LectureReviewDigest?
    do {
      let updates = await foundationModelsUseCase.streamReviewDigest(of: reviews)
      for try await update in updates {
        try Task.checkCancellation()
        switch update {
        case let .started(reviewCount):
          self.reviewCount = reviewCount
        case let .reading(completed, total):
          phase = .reading(completed: completed, total: total)
        case let .writing(snapshot):
          digest = snapshot
          phase = .writing(snapshot)
        }
      }
      try Task.checkCancellation()
      guard let digest, digest.overview?.isEmpty == false else {
        throw LectureReviewDigestError.failed
      }
      phase = .finished(digest)
      analyticsService?.logEvent(ReviewDigestEvent.finished(source: source))
    } catch {
      if error is CancellationError || Task.isCancelled {
        phase = .idle
        return
      }
      let reason = error as? LectureReviewDigestError ?? .failed
      phase = .failed(message: Self.message(for: reason))
      analyticsService?.logEvent(ReviewDigestEvent.failed(source: source, reason: reason))
    }
  }

  /// Asks for a summary of `reviews`: the first when summaries aren't
  /// automatic, or another after one failed.
  func requestSummary(of reviews: [LectureReview]) {
    requestedReviewIDs = reviews.map(\.id)
    phase = .idle
    attempt += 1
  }

  private static func readableCount(of reviews: [LectureReview]) -> Int {
    reviews.count { !$0.isDeleted && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
  }

  private static func message(for error: LectureReviewDigestError) -> String {
    switch error {
    case .unavailable:
      String(localized: "Apple Intelligence isn't available right now. Check that it's turned on in Settings, then try again.", bundle: .module)
    case .noReviews:
      String(localized: "There are no reviews to summarise.", bundle: .module)
    case .unsafeContent:
      String(localized: "Some of these reviews can't be summarised.", bundle: .module)
    case .failed:
      String(localized: "The reviews couldn't be summarised. Please try again.", bundle: .module)
    }
  }
}
