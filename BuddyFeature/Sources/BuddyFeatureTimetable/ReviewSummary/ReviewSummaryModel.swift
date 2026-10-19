//
//  ReviewSummaryModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 12/10/2026.
//

import Foundation
import Observation
import Factory
import BuddyDomain

/// Summarises single reviews on request, for the review lists of the lecture
/// and course screens.
///
/// Owned by the screen rather than each review cell, which a lazy list drops
/// when it scrolls away: a summary stays put, and one still being written keeps
/// going.
@MainActor
@Observable
final class ReviewSummaryModel {
  enum Phase: Equatable {
    /// The summary written so far; empty until the first words arrive.
    case summarising(String)
    case finished(String)
    case failed(message: String)
  }

  /// Shorter reviews are quicker to read than a summary of them.
  static let minimumReviewLength = 200

  private(set) var isAvailable = false
  /// By review ID.
  private(set) var phases: [Int: Phase] = [:]

  @ObservationIgnored @Injected(
    \.foundationModelsUseCase
  ) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  /// The screen the reviews are on, for analytics.
  @ObservationIgnored private let source: String

  init(source: String) {
    self.source = source
  }

  func checkAvailability() async {
    isAvailable = await foundationModelsUseCase?.isAvailable() ?? false
  }

  /// Whether `review` is long enough to be worth summarising on this device.
  func canSummarise(_ review: LectureReview) -> Bool {
    isAvailable && !review.isDeleted
      && review.content.trimmingCharacters(in: .whitespacesAndNewlines).count >= Self.minimumReviewLength
  }

  func phase(for review: LectureReview) -> Phase? {
    phases[review.id]
  }

  /// Summarises `review`, or tries again after a failure. A summary already
  /// written or being written is left alone.
  func summarise(_ review: LectureReview) {
    guard let foundationModelsUseCase, canSummarise(review) else { return }
    switch phases[review.id] {
    case .summarising, .finished: return
    case .failed, nil: break
    }

    let id = review.id
    phases[id] = .summarising("")
    analyticsService?.logEvent(ReviewSummaryEvent.requested(source: source))

    Task {
      var summary = ""
      do {
        for try await snapshot in await foundationModelsUseCase.streamSummary(of: review.content, as: .lectureReview) {
          summary = snapshot
          phases[id] = .summarising(snapshot)
        }
        summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else { throw SummarisationError.failed }
        phases[id] = .finished(summary)
        analyticsService?.logEvent(ReviewSummaryEvent.finished(source: source))
      } catch {
        let reason = error as? SummarisationError ?? .failed
        phases[id] = .failed(message: reason.localizedDescription)
        analyticsService?.logEvent(ReviewSummaryEvent.failed(source: source, reason: reason))
      }
    }
  }
}
