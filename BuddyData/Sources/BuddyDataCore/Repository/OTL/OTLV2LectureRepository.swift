//
//  OTLV2LectureRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLV2LectureRepository: OTLV2LectureRepositoryProtocol, Sendable {
  public let provider: MoyaProvider<OTLV2LectureTarget>

  public init(provider: MoyaProvider<OTLV2LectureTarget>) {
    self.provider = provider
  }

  public func searchLecture(request: LectureSearchRequest) async throws -> [V2CourseLecture] {
    let response = try await self.provider.request(
      .searchLecture(request: LectureSearchRequestDTO.fromModel(model: request))
    )
    let result = try response.map(V2CourseLecturePageDTO.self)

    return result.courses.compactMap { $0.toModel() }
  }
}
