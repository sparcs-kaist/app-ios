//
//  OTLReviewRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLReviewRepository: OTLReviewRepositoryProtocol, Sendable {
  public let provider: MoyaProvider<OTLReviewTarget>

  public init(provider: MoyaProvider<OTLReviewTarget>) {
    self.provider = provider
  }

  public func fetchReviews(courseID: Int, professorID: Int?, offset: Int, limit: Int) async throws -> LectureReviewPage {
    let response = try await provider.request(
      .fetchReviews(courseID: courseID, professorID: professorID, offset: offset, limit: limit)
    )
    let result = try response.map(LectureReviewPageDTO.self).toModel()

    return result
  }

  public func writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int) async throws {
    _ = try await provider
      .request(
        .writeReview(
          lectureID: lectureID,
          content: content,
          grade: grade,
          load: load,
          speech: speech
        )
      )
  }

  public func likeReview(reviewID: Int) async throws {
    _ = try await provider.request(.likeReview(reviewID: reviewID))
  }

  public func unlikeReview(reviewID: Int) async throws {
    _ = try await provider.request(.unlikeReview(reviewID: reviewID))
  }
}
