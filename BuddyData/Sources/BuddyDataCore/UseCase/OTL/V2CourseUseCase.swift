//
//  V2CourseUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class V2CourseUseCase: V2CourseUseCaseProtocol, Sendable {
  // MARK: - Dependencies
  private let otlCourseRepository: OTLV2CourseRepositoryProtocol

  // MARK: - Initialiser
  public init(otlCourseRepository: OTLV2CourseRepositoryProtocol) {
    self.otlCourseRepository = otlCourseRepository
  }

  // MARK: - Functions
  public func searchCourse(request: CourseSearchRequest) async throws -> [V2CourseSummary] {
    try await otlCourseRepository.searchCourse(request: request)
  }

  public func getCourse(courseID: Int) async throws -> V2Course {
    try await otlCourseRepository.getCourse(courseID: courseID)
  }
}
