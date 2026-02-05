//
//  FeedCommentUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import Foundation
import BuddyDomain

public final class FeedCommentUseCase: FeedCommentUseCaseProtocol {
  // MARK: - Properties
  private let feature: String = "FeedComment"
  // MARK: - Dependencies
  private let feedCommentRepository: FeedCommentRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Initialiser
  public init(
    feedCommentRepository: FeedCommentRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.feedCommentRepository = feedCommentRepository
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func fetchComments(postID: String) async throws -> [FeedComment] {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": postID
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository.fetchComments(postID: postID)
    }
  }

  public func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": postID,
        "content": request.content,
        "isAnonymous": "\(request.isAnonymous)",
        "hasImages": "\(request.image != nil)"
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository.writeComment(postID: postID, request: request)
    }
  }

  public func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": commentID,
        "content": request.content,
        "isAnonymous": "\(request.isAnonymous)",
        "hasImages": "\(request.image != nil)"
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository.writeReply(commentID: commentID, request: request)
    }
  }

  public func deleteComment(commentID: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": commentID
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository.deleteComment(commentID: commentID)
    }
  }

  public func vote(commentID: String, type: FeedVoteType) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": commentID,
        "type": type.rawValue
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository.vote(commentID: commentID, type: type)
    }
  }

  public func deleteVote(commentID: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": commentID
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository.deleteVote(commentID: commentID)
    }
  }

  public func reportComment(commentID: String, reason: FeedReportType, detail: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": commentID,
        "reason": reason.rawValue,
        "detail": detail
      ]
    )

    return try await execute(context: context) {
      try await feedCommentRepository
        .reportComment(commentID: commentID, reason: reason, detail: detail)
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
        throw FeedCommentUseCaseError.cannotDeleteCommentWithVote
      }

      crashlyticsService?.record(error: networkError, context: context)
      throw networkError
    } catch {
      let mappedError = FeedCommentUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
