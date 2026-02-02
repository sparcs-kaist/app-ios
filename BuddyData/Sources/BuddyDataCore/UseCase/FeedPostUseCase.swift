//
//  FeedPostUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 31/01/2026.
//

import Foundation
import BuddyDomain

public enum FeedPostUseCaseError: Error, LocalizedError, Sendable {
  case noFeedPostRepository
  case cannotDeletePostWithVoteOrComment
  case unknown(underlying: Error?)

  public var errorDescription: String? {
    switch self {
    case .noFeedPostRepository:
      return String(localized: "Unable to load feed. Please try again later.")
    case .cannotDeletePostWithVoteOrComment:
      return String(localized: "Cannot delete post that has votes or comments.")
    case .unknown:
      return String(localized: "Unknown error occurred. Please try again.")
    }
  }
}

public final class FeedPostUseCase {
  // MARK: - Dependencies
  private let feedPostRepository: FeedPostRepositoryProtocol?
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    feedPostRepository: FeedPostRepositoryProtocol?,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.feedPostRepository = feedPostRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    guard let feedPostRepository else {
      let error = FeedPostUseCaseError.noFeedPostRepository

      crashlyticsService?.recordException(error: error)
      throw error
    }

    do {
      return try await feedPostRepository.fetchPosts(cursor: cursor, page: page)
    } catch let networkError as NetworkError {
      if networkError.isRecordable {
        crashlyticsService?.recordException(error: networkError)
      }
      throw networkError
    } catch {
      let mappedError = FeedPostUseCaseError.unknown(underlying: error)
      crashlyticsService?.recordException(error: error)
      throw mappedError
    }
  }

  public func writePost(request: FeedCreatePost) async throws {
    guard let feedPostRepository else {
      let error = FeedPostUseCaseError.noFeedPostRepository

      crashlyticsService?.recordException(error: error)
      throw error
    }

    do {
      try await feedPostRepository.writePost(request: request)
    } catch let networkError as NetworkError {
      if networkError.isRecordable {
        crashlyticsService?.recordException(error: networkError)
      }
      throw networkError
    } catch {
      let mappedError = FeedPostUseCaseError.unknown(underlying: error)
      crashlyticsService?.recordException(error: error)
      throw mappedError
    }
  }

  public func deletePost(postID: String) async throws {
    guard let feedPostRepository else {
      let error = FeedPostUseCaseError.noFeedPostRepository

      crashlyticsService?.recordException(error: error)
      throw error
    }

    do {
      try await feedPostRepository.deletePost(postID: postID)
    } catch let networkError as NetworkError {
      if case .serverError(let statusCode) = networkError,
        statusCode == 409 {
        throw FeedPostUseCaseError.cannotDeletePostWithVoteOrComment
      }

      if networkError.isRecordable {
        crashlyticsService?.recordException(error: networkError)
      }
      throw networkError
    } catch {
      let mappedError = FeedPostUseCaseError.unknown(underlying: error)
      crashlyticsService?.recordException(error: error)
      throw mappedError
    }
  }

  public func vote(postID: String, type: FeedVoteType) async throws {
    guard let feedPostRepository else {
      let error = FeedPostUseCaseError.noFeedPostRepository

      crashlyticsService?.recordException(error: error)
      throw error
    }

    do {
      try await feedPostRepository.vote(postID: postID, type: type)
    } catch let networkError as NetworkError {
      if networkError.isRecordable {
        crashlyticsService?.recordException(error: networkError)
      }
      throw networkError
    } catch {
      let mappedError = FeedPostUseCaseError.unknown(underlying: error)
      crashlyticsService?.recordException(error: error)
      throw mappedError
    }
  }

  public func deleteVote(postID: String) async throws {
    guard let feedPostRepository else {
      let error = FeedPostUseCaseError.noFeedPostRepository

      crashlyticsService?.recordException(error: error)
      throw error
    }

    do {
      try await feedPostRepository.deleteVote(postID: postID)
    } catch let networkError as NetworkError {
      if networkError.isRecordable {
        crashlyticsService?.recordException(error: networkError)
      }
      throw networkError
    } catch {
      let mappedError = FeedPostUseCaseError.unknown(underlying: error)
      crashlyticsService?.recordException(error: error)
      throw mappedError
    }
  }

  public func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {
    
  }
}
