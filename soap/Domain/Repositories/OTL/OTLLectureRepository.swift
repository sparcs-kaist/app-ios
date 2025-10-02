//
//  OTLLectureRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation

@preconcurrency
import Moya

protocol OTLLectureRepositoryProtocol: Sendable {
  func searchLectures(request: LectureSearchRequest) async throws -> [Lecture]
  func fetchLectures(lectureID: Int) async throws -> [LectureReview]
}

final class OTLLectureRepository: OTLLectureRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLLectureTarget>

  init(provider: MoyaProvider<OTLLectureTarget>) {
    self.provider = provider
  }

  func searchLectures(request: LectureSearchRequest) async throws -> [Lecture] {
    let response = try await self.provider.request(
      .searchLecture(request: LectureSearchRequestDTO.fromModel(model: request))
    )
    let result = try response.map([LectureDTO].self).compactMap { $0.toModel() }

    return result
  }

  func fetchLectures(lectureID: Int) async throws -> [LectureReview] {
    let response = try await self.provider.request(.fetchReviews(lectureID: lectureID))
    let result = try response.map([LectureReviewDTO].self).compactMap { $0.toModel() }

    return result
  }
}
