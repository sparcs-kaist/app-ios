//
//  FeedProfileUseCase.swift
//  BuddyDataiOS
//
//  Created by 하정우 on 2/20/26.
//

import Foundation
import BuddyDomain
import UIKit

public final class FeedProfileUseCase: FeedProfileUseCaseProtocol {
  // MARK: - Properties
  private let feature = "FeedProfile"
  
  // MARK: - Dependencies
  private let feedProfileRepository: FeedProfileRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?
  
  // MARK: - Initialiser
  public init(
    feedProfileRepository: FeedProfileRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.feedProfileRepository = feedProfileRepository
    self.crashlyticsService = crashlyticsService
  }
  
  // MARK: - Functions
  public func updateNickname(nickname: String) async throws {
    let context = CrashContext(feature: feature, metadata: ["nickname": nickname])
    
    try await execute(context: context) {
      try await feedProfileRepository.updateNickname(nickname: nickname)
    }
  }
  
  public func updateProfileImage(image: UIImage?) async throws {
    let context = CrashContext(feature: feature, metadata: ["resetProfileImage": "\(image == nil)"])
    
    try await execute(context: context) {
      if let image {
        try await feedProfileRepository.setProfileImage(image: image)
      } else {
        try await feedProfileRepository.removeProfileImage()
      }
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
      let mappedError = FeedProfileUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
