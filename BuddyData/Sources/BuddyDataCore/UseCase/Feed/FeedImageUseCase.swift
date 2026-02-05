//
//  FeedImageUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import Foundation
import BuddyDomain

public final class FeedImageUseCase: FeedImageUseCaseProtocol {
  // MARK: - Properties
  private let feature: String = "FeedImage"
  // MARK: - Dependencies
  private let feedImageRepository: FeedImageRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    feedImageRepository: FeedImageRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.feedImageRepository = feedImageRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func uploadPostImage(item: FeedPostPhotoItem) async throws -> FeedImage {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "hasSpoiler": "\(item.spoiler)",
        "hasDescription": item.description.isEmpty ? "false" : "true"
      ]
    )

    return try await execute(context: context) {
      try await feedImageRepository.uploadPostImage(item: item)
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
      let mappedError = FeedImageUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
