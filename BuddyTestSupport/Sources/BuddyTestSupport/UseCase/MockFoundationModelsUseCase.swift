//
//  MockFoundationModelsUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import BuddyDomain

public actor MockFoundationModelsUseCase: FoundationModelsUseCaseProtocol {
  var isAvailableValue: Bool = false
  var summariseResult: String = ""
  var summaryError: (any Error)?
  /// The snapshots a generation streams, in order, as the real model's would
  /// arrive: partly filled in at first, complete by the last one.
  var themeBriefs: [TimetableThemeBrief] = []
  var themeBriefError: (any Error)?
  /// The updates a review digest streams, in order.
  var reviewDigestProgress: [LectureReviewDigestProgress] = []
  var reviewDigestError: (any Error)?
  var parsedActivity = ParsedActivity()
  var parseActivityError: (any Error)?
  /// The descriptions `parseActivity(_:today:)` was asked to read, in order.
  public private(set) var parsedDescriptions: [String] = []

  public init() { }

  /// Sets whether the model is available and what `streamSummary(of:as:)` gives back.
  public func stubSummary(isAvailable: Bool = true, summary: String = "", error: (any Error)? = nil) {
    isAvailableValue = isAvailable
    summariseResult = summary
    summaryError = error
  }

  public func isAvailable() async -> Bool {
    isAvailableValue
  }

  /// Streams the stubbed summary in one update, or fails with the stubbed error.
  public func streamSummary(of text: String, as kind: SummaryKind) -> AsyncThrowingStream<String, any Error> {
    let summary = summariseResult
    let error = summaryError
    return AsyncThrowingStream { continuation in
      if error == nil { continuation.yield(summary) }
      continuation.finish(throwing: error)
    }
  }

  public func streamThemeBrief(
    describing description: String,
    variation: UInt64
  ) -> AsyncThrowingStream<TimetableThemeBrief, any Error> {
    let briefs = themeBriefs
    let error = themeBriefError
    return AsyncThrowingStream { continuation in
      for brief in briefs {
        continuation.yield(brief)
      }
      continuation.finish(throwing: error)
    }
  }

  public func streamReviewDigest(
    of reviews: [LectureReview]
  ) -> AsyncThrowingStream<LectureReviewDigestProgress, any Error> {
    let progress = reviewDigestProgress
    let error = reviewDigestError
    return AsyncThrowingStream { continuation in
      for update in progress {
        continuation.yield(update)
      }
      continuation.finish(throwing: error)
    }
  }

  public func parseActivity(_ description: String, today: DayType) async throws -> ParsedActivity {
    parsedDescriptions.append(description)
    if let parseActivityError { throw parseActivityError }
    return parsedActivity
  }

  /// Actors have no settable properties from the outside, so the stubs are set
  /// through here.
  public func stub(isAvailable: Bool? = nil, summarise: String? = nil, summaryError: (any Error)? = nil) {
    if let isAvailable { isAvailableValue = isAvailable }
    if let summarise { summariseResult = summarise }
    self.summaryError = summaryError
  }

  public func stub(themeBriefs: [TimetableThemeBrief] = [], error: (any Error)? = nil) {
    self.themeBriefs = themeBriefs
    self.themeBriefError = error
  }

  public func stub(reviewDigest progress: [LectureReviewDigestProgress], error: (any Error)? = nil) {
    self.reviewDigestProgress = progress
    self.reviewDigestError = error
  }

  public func stub(parsedActivity: ParsedActivity = ParsedActivity(), error: (any Error)? = nil) {
    self.parsedActivity = parsedActivity
    self.parseActivityError = error
  }
}
