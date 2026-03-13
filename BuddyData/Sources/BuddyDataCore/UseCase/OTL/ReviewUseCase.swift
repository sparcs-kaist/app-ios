//
//  ReviewUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class ReviewUseCase: ReviewUseCaseProtocol, Sendable {
  // MARK: - Properties
  private let feature: String = "Review"
  // MARK: - Dependencies
  private let otlReviewRepository: OTLReviewRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlReviewRepository: OTLReviewRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol? = nil
  ) {
    self.otlReviewRepository = otlReviewRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func fetchReviews(courseID: Int, professorID: Int?, offset: Int, limit: Int) async throws -> LectureReviewPage {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "courseID": "\(courseID)",
        "professorID": "\(String(describing: professorID ?? nil))",
        "offset": "\(offset)",
        "limit": "\(limit)"
      ]
    )

    return try await execute(context: context) {
      try await self.otlReviewRepository
        .fetchReviews(courseID: courseID, professorID: professorID, offset: offset, limit: limit)
    }
  }

  public func writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "lectureID": "\(lectureID)",
        "grade": "\(grade)",
        "load": "\(load)",
        "speech": "\(speech)"
      ]
    )

    try await execute(context: context) {
      try await self.otlReviewRepository
        .writeReview(lectureID: lectureID, content: content, grade: grade, load: load, speech: speech)
    }
  }

  public func likeReview(reviewID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["reviewID": "\(reviewID)"]
    )

    try await execute(context: context) {
      try await self.otlReviewRepository.likeReview(reviewID: reviewID)
    }
  }

  public func unlikeReview(reviewID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["reviewID": "\(reviewID)"]
    )

    try await execute(context: context) {
      try await self.otlReviewRepository.unlikeReview(reviewID: reviewID)
    }
  }

  // MARK: - Private
  private func execute<T>(
    context: CrashContext,
    _ operation: () async throws -> T
  ) async throws -> T {
    do {
      return try await operation()
    } catch let networkError as NetworkError {
      crashlyticsService?.record(error: networkError, context: context)
      throw networkError
    } catch {
      let mappedError = ReviewUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
