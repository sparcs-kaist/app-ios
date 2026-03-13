//
//  LectureUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class LectureUseCase: LectureUseCaseProtocol, Sendable {
  // MARK: - Properties
  private let feature: String = "Lecture"
  // MARK: - Dependencies
  private let otlLectureRepository: OTLLectureRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlLectureRepository: OTLLectureRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol? = nil
  ) {
    self.otlLectureRepository = otlLectureRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func searchLecture(request: LectureSearchRequest) async throws -> [CourseLecture] {
    let context = CrashContext(
      feature: feature,
      metadata: ["keyword": "\(request)"]
    )

    return try await execute(context: context) {
      try await self.otlLectureRepository.searchLecture(request: request)
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
      let mappedError = LectureUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
