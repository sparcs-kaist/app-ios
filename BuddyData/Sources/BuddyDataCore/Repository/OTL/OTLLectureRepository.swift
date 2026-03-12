//
//  OTLLectureRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLLectureRepository: OTLLectureRepositoryProtocol, Sendable {
  public let provider: MoyaProvider<OTLLectureTarget>

  public init(provider: MoyaProvider<OTLLectureTarget>) {
    self.provider = provider
  }

  public func searchLecture(request: LectureSearchRequest) async throws -> [CourseLecture] {
    let response = try await self.provider.request(
      .searchLecture(request: LectureSearchRequestDTO.fromModel(model: request))
    )
    let result = try response.map(CourseLecturePageDTO.self)

    return result.courses.compactMap { $0.toModel() }
  }
}
