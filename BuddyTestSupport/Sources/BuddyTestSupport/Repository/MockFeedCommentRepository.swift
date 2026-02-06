//
//  MockFeedCommentRepository.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation
import BuddyDomain

public final class MockFeedCommentRepository: FeedCommentRepositoryProtocol, @unchecked Sendable {
  public var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
  public var writeCommentResult: Result<FeedComment, Error>?
  public var writeReplyResult: Result<FeedComment, Error>?
  public var deleteCommentResult: Result<Void, Error> = .success(())
  public var voteResult: Result<Void, Error> = .success(())
  var deleteVoteResult: Result<Void, Error> = .success(())
  var reportCommentResult: Result<Void, Error> = .success(())

  public var fetchCommentsCallCount = 0
  public var writeCommentCallCount = 0
  public var writeReplyCallCount = 0
  public var deleteCommentCallCount = 0
  public var voteCallCount = 0
  public var deleteVoteCallCount = 0
  public var reportCommentCallCount = 0

  public var lastFetchPostID: String?
  public var lastWriteCommentPostID: String?
  public var lastWriteCommentRequest: FeedCreateComment?
  public var lastWriteReplyCommentID: String?
  var lastWriteReplyRequest: FeedCreateComment?
  public var lastDeleteCommentID: String?
  public var lastVoteCommentID: String?
  public var lastVoteType: FeedVoteType?
  public var lastDeleteVoteCommentID: String?
  public var lastReportCommentID: String?
  public var lastReportReason: FeedReportType?
  public var lastReportDetail: String?

  public init() { }

  public func fetchComments(postID: String) async throws -> [FeedComment] {
    fetchCommentsCallCount += 1
    lastFetchPostID = postID
    return try fetchCommentsResult.get()
  }

  public func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    writeCommentCallCount += 1
    lastWriteCommentPostID = postID
    lastWriteCommentRequest = request
    guard let result = writeCommentResult else {
      throw TestError.notConfigured
    }
    return try result.get()
  }

  public func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
    writeReplyCallCount += 1
    lastWriteReplyCommentID = commentID
    lastWriteReplyRequest = request
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
    lastReportDetail = detail
    try reportCommentResult.get()
  }
}
