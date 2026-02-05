//
//  FeedPostUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 31/01/2026.
//

import Foundation
import BuddyDomain

public final class FeedPostUseCase: FeedPostUseCaseProtocol {
  // MARK: - Properties
  private let feature: String = "FeedPost"
  // MARK: - Dependencies
  private let feedPostRepository: FeedPostRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    feedPostRepository: FeedPostRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.feedPostRepository = feedPostRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "cursor": "\(String(describing: cursor ?? "nil"))",
        "page": "\(page))"
      ]
    )

    return try await execute(context: context) {
      try await feedPostRepository.fetchPosts(cursor: cursor, page: page)
    }
  }

  public func writePost(request: FeedCreatePost) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "content": request.content,
        "hasImages": request.images.isEmpty ? "false" : "true",
        "isAnonymous": "\(request.isAnonymous)"
      ]
    )

    try await execute(context: context) {
      try await feedPostRepository.writePost(request: request)
    }
  }

  public func deletePost(postID: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": postID
      ]
    )

    try await execute(context: context) {
      try await feedPostRepository.deletePost(postID: postID)
    }
  }

  public func vote(postID: String, type: FeedVoteType) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": postID,
        "type": "\(type)"
      ]
    )

    try await execute(context: context) {
      try await feedPostRepository.vote(postID: postID, type: type)
    }
  }

  public func deleteVote(postID: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": postID
      ]
    )

    try await execute(context: context) {
      try await feedPostRepository.deleteVote(postID: postID)
    }
  }

  public func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": postID,
        "reason": "\(reason)",
        "detail": detail
      ]
    )

    try await execute(context: context) {
      try await feedPostRepository.reportPost(postID: postID, reason: reason, detail: detail)
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
      if case .serverError(let statusCode) = networkError,
         statusCode == 409 {
        throw FeedPostUseCaseError.cannotDeletePostWithVoteOrComment
      }

      crashlyticsService?.record(error: networkError, context: context)
      throw networkError
    } catch {
      let mappedError = FeedPostUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
