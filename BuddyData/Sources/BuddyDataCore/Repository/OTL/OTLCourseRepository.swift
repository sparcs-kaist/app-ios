//
//  OTLCourseRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLCourseRepository: OTLCourseRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLCourseTarget>

  public init(provider: MoyaProvider<OTLCourseTarget>) {
    self.provider = provider
  }

  public func searchCourse(request: CourseSearchRequest) async throws -> [CourseSummary] {
    let response = try await self.provider.request(
      .searchCourse(request: CourseSearchRequestDTO.fromModel(model: request))
    )
    let result = try response.map(CoursePageDTO.self)

    return result.courses.compactMap { $0.toModel() }
  }

  public func getCourse(courseID: Int) async throws -> Course {
    let response = try await self.provider.request(.fetchCourse(courseID: courseID))

    return try response.map(CourseDTO.self).toModel()
  }
}
