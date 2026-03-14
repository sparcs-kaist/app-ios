//
//  DepartmentUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import Foundation
import BuddyDomain

public final class DepartmentUseCase: DepartmentUseCaseProtocol, Sendable {
  // MARK: - Properties
  private let feature: String = "Department"
  // MARK: - Dependencies
  private let otlDepartmentRepository: OTLDepartmentRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlDepartmentRepository: OTLDepartmentRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol? = nil
  ) {
    self.otlDepartmentRepository = otlDepartmentRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func getDepartments() async throws -> [Department] {
    let context = CrashContext(feature: feature)

    return try await execute(context: context) {
      try await self.otlDepartmentRepository.getDepartments()
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
      let mappedError = DepartmentUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
