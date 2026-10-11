//
//  WishlistUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import Foundation
import BuddyDomain

public final class WishlistUseCase: WishlistUseCaseProtocol, Sendable {
  // MARK: - Properties
  private let feature: String = "Wishlist"
  // MARK: - Dependencies
  private let otlUserRepository: OTLUserRepositoryProtocol?
  private let userUseCase: UserUseCaseProtocol?
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlUserRepository: OTLUserRepositoryProtocol?,
    userUseCase: UserUseCaseProtocol?,
    crashlyticsService: CrashlyticsServiceProtocol? = nil
  ) {
    self.otlUserRepository = otlUserRepository
    self.userUseCase = userUseCase
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func fetchWishlist(semester: Semester) async throws -> [CourseLecture] {
    let context = CrashContext(feature: feature, metadata: ["semester": semester.id])
    return try await execute(context: context) {
      try await self.repository().fetchWishlist(userID: try await self.userID(), semester: semester)
    }
  }

  public func setWishlisted(_ isWishlisted: Bool, lectureID: Int) async throws {
    let context = CrashContext(feature: feature, metadata: ["lectureID": "\(lectureID)", "add": "\(isWishlisted)"])
    try await execute(context: context) {
      try await self.repository().updateWishlist(
        userID: try await self.userID(),
        lectureID: lectureID,
        isWishlisted: isWishlisted
      )
    }
  }

  // MARK: - Private
  private func repository() throws -> OTLUserRepositoryProtocol {
    guard let otlUserRepository else { throw NetworkError.unauthorized }
    return otlUserRepository
  }

  /// The wishlist routes take the OTL user's ID, which must match the session.
  private func userID() async throws -> Int {
    guard let userUseCase else { throw NetworkError.unauthorized }
    if await userUseCase.otlUser == nil {
      try await userUseCase.fetchOTLUser()
    }
    guard let user = await userUseCase.otlUser else { throw NetworkError.unauthorized }
    return user.id
  }

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
