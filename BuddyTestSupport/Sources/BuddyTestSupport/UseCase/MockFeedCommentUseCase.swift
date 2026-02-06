//
//  MockFeedCommentUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import BuddyDomain
import Foundation

public final class MockFeedCommentUseCase: FeedCommentUseCaseProtocol, @unchecked Sendable {
  var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
  var writeCommentResult: Result<FeedComment, Error>?
  var writeReplyResult: Result<FeedComment, Error>?
  public var deleteCommentResult: Result<Void, Error> = .success(())
  public var voteResult: Result<Void, Error> = .success(())
  var deleteVoteResult: Result<Void, Error> = .success(())
  public var reportCommentResult: Result<Void, Error> = .success(())

  public var voteCallCount = 0
  public var deleteVoteCallCount = 0
  public var deleteCommentCallCount = 0
  public var reportCommentCallCount = 0

  var lastVoteCommentID: String?
  public var lastVoteType: FeedVoteType?
  var lastDeleteVoteCommentID: String?
  public var lastDeleteCommentID: String?
  public var lastReportCommentID: String?
  public var lastReportReason: FeedReportType?

  public init() { }

  public func fetchComments(postID: String) async throws -> [FeedComment] {
    try fetchCommentsResult.get()
  }

  public func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    guard let result = writeCommentResult else {
      throw TestError.notConfigured
    }
    return try result.get()
  }

  public func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
    guard let result = writeReplyResult else {
      throw TestError.notConfigured
    }
    return try result.get()
  }

  public func deleteComment(commentID: String) async throws {
    deleteCommentCallCount += 1
    lastDeleteCommentID = commentID
    try deleteCommentResult.get()
  }

  public func vote(commentID: String, type: FeedVoteType) async throws {
    voteCallCount += 1
    lastVoteCommentID = commentID
    lastVoteType = type
    try voteResult.get()
  }

  public func deleteVote(commentID: String) async throws {
    deleteVoteCallCount += 1
    lastDeleteVoteCommentID = commentID
    try deleteVoteResult.get()
  }

  public func reportComment(commentID: String, reason: FeedReportType, detail: String) async throws {
    reportCommentCallCount += 1
    lastReportCommentID = commentID
    lastReportReason = reason
    try reportCommentResult.get()
  }
}
