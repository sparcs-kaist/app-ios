//
//  OTLV2CourseRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLV2CourseRepository: OTLV2CourseRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLV2CourseTarget>

  public init(provider: MoyaProvider<OTLV2CourseTarget>) {
    self.provider = provider
  }

  public func searchCourse(request: CourseSearchRequest) async throws -> [V2CourseSummary] {
    let response = try await self.provider.request(
      .searchCourse(request: CourseSearchRequestDTO.fromModel(model: request))
    )
    let result = try response.map(V2CoursePageDTO.self)

    return result.courses.compactMap { $0.toModel() }
  }

  public func getCourse(courseID: Int) async throws -> V2Course {
    let response = try await self.provider.request(.fetchCourse(courseID: courseID))

    return try response.map(V2CourseDTO.self).toModel()
  }
}
