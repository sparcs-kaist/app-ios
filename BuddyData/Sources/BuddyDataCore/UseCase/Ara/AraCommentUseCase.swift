//
//  AraCommentUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import BuddyDomain

public final class AraCommentUseCase: AraCommentUseCaseProtocol {
  private let feature: String = "AraComment"
  private let araCommentRepository: AraCommentRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  public init(
    araCommentRepository: AraCommentRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.araCommentRepository = araCommentRepository
    self.crashlyticsService = crashlyticsService
  }

  public func upvoteComment(commentID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["commentID": "\(commentID)"]
    )
    try await execute(context: context) {
      try await araCommentRepository.upvoteComment(commentID: commentID)
    }
  }

  public func downvoteComment(commentID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["commentID": "\(commentID)"]
    )
    try await execute(context: context) {
      try await araCommentRepository.downvoteComment(commentID: commentID)
    }
  }

  public func cancelVote(commentID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["commentID": "\(commentID)"]
    )
    try await execute(context: context) {
      try await araCommentRepository.cancelVote(commentID: commentID)
    }
  }

  public func writeComment(postID: Int, content: String) async throws -> AraPostComment {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": "\(postID)",
        "content": content
      ]
    )
    return try await execute(context: context) {
      try await araCommentRepository.writeComment(postID: postID, content: content)
    }
  }

  public func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": "\(commentID)",
        "content": content
      ]
    )
    return try await execute(context: context) {
      try await araCommentRepository.writeThreadedComment(commentID: commentID, content: content)
    }
  }

  public func deleteComment(commentID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["commentID": "\(commentID)"]
    )
    try await execute(context: context) {
      try await araCommentRepository.deleteComment(commentID: commentID)
    }
  }

  public func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": "\(commentID)",
        "content": content
      ]
    )
    return try await execute(context: context) {
      try await araCommentRepository.editComment(commentID: commentID, content: content)
    }
  }

  public func reportComment(commentID: Int, type: AraContentReportType) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "commentID": "\(commentID)",
        "type": "\(type)"
      ]
    )
    try await execute(context: context) {
      try await araCommentRepository.reportComment(commentID: commentID, type: type)
    }
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
      let mappedError = AraCommentUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
