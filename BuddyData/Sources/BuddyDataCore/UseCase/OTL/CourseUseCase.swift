//
//  CourseUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class CourseUseCase: CourseUseCaseProtocol, Sendable {
  // MARK: - Dependencies
  private let otlCourseRepository: OTLCourseRepositoryProtocol

  // MARK: - Initialiser
  public init(otlCourseRepository: OTLCourseRepositoryProtocol) {
    self.otlCourseRepository = otlCourseRepository
  }

  // MARK: - Functions
  public func searchCourse(request: CourseSearchRequest) async throws -> [CourseSummary] {
    try await otlCourseRepository.searchCourse(request: request)
  }

  public func getCourse(courseID: Int) async throws -> Course {
    try await otlCourseRepository.getCourse(courseID: courseID)
  }
}
