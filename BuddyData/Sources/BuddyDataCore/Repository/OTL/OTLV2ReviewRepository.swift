//
//  OTLV2ReviewRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLV2ReviewRepository: OTLV2ReviewRepositoryProtocol, Sendable {
  public let provider: MoyaProvider<OTLV2ReviewTarget>

  public init(provider: MoyaProvider<OTLV2ReviewTarget>) {
    self.provider = provider
  }

  public func fetchReviews(courseID: Int, professorID: Int?, offset: Int, limit: Int) async throws -> V2LectureReviewPage {
    let response = try await provider.request(
      .fetchReviews(courseID: courseID, professorID: professorID, offset: offset, limit: limit)
    )
    let result = try response.map(V2LectureReviewPageDTO.self).toModel()

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
