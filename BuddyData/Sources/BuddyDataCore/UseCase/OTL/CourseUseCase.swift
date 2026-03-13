//
//  CourseUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class CourseUseCase: CourseUseCaseProtocol, Sendable {
  // MARK: - Properties
  private let feature: String = "Course"
  // MARK: - Dependencies
  private let otlCourseRepository: OTLCourseRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlCourseRepository: OTLCourseRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol? = nil
  ) {
    self.otlCourseRepository = otlCourseRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func searchCourse(request: CourseSearchRequest) async throws -> [CourseSummary] {
    let context = CrashContext(
      feature: feature,
      metadata: ["keyword": "\(request)"]
    )

    return try await execute(context: context) {
      try await self.otlCourseRepository.searchCourse(request: request)
    }
  }

  public func getCourse(courseID: Int) async throws -> Course {
    let context = CrashContext(
      feature: feature,
      metadata: ["courseID": "\(courseID)"]
    )

    return try await execute(context: context) {
      try await self.otlCourseRepository.getCourse(courseID: courseID)
    }
  }

  // MARK: - Private
  private func execute<T>(
    context: CrashContext,
    _ operation: () async throws -> T
  ) async throws -> T {
    do {
      return try await operation()
    } catch let networkError as NetworkError {
      crashlyticsService?.record(error: networkError, context: context)
      throw networkError
    } catch {
      let mappedError = CourseUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
