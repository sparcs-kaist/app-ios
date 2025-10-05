//
//  OTLLectureRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLLectureRepository: OTLLectureRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLLectureTarget>

  public init(provider: MoyaProvider<OTLLectureTarget>) {
    self.provider = provider
  }

  public func searchLectures(request: LectureSearchRequest) async throws -> [Lecture] {
    let response = try await self.provider.request(
      .searchLecture(request: LectureSearchRequestDTO.fromModel(model: request))
    )
    let result = try response.map([LectureDTO].self).compactMap { $0.toModel() }

    return result
  }

  public func fetchLectures(lectureID: Int) async throws -> [LectureReview] {
    let response = try await self.provider.request(.fetchReviews(lectureID: lectureID))
    let result = try response.map([LectureReviewDTO].self).compactMap { $0.toModel() }

    return result
  }

  public func writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int) async throws -> LectureReview {
    let response = try await self.provider.request(
      .writeReview(lectureID: lectureID, content: content, grade: grade, load: load, speech: speech)
    )
    let result = try response.map(LectureReviewDTO.self).toModel()

    return result
  }
}
