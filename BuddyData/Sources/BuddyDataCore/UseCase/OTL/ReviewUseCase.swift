//
//  ReviewUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class ReviewUseCase: ReviewUseCaseProtocol, Sendable {
  // MARK: - Dependencies
  private let otlReviewRepository: OTLReviewRepositoryProtocol

  // MARK: - Initialiser
  public init(otlReviewRepository: OTLReviewRepositoryProtocol) {
    self.otlReviewRepository = otlReviewRepository
  }

  // MARK: - Functions
  public func fetchReviews(courseID: Int, professorID: Int?, offset: Int, limit: Int) async throws -> LectureReviewPage {
    try await otlReviewRepository
      .fetchReviews(courseID: courseID, professorID: professorID, offset: offset, limit: limit)
  }

  public func writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int) async throws {
    try await otlReviewRepository
      .writeReview(lectureID: lectureID, content: content, grade: grade, load: load, speech: speech)
  }

  public func likeReview(reviewID: Int) async throws {
    try await otlReviewRepository.likeReview(reviewID: reviewID)
  }

  public func unlikeReview(reviewID: Int) async throws {
    try await otlReviewRepository.unlikeReview(reviewID: reviewID)
  }
}
