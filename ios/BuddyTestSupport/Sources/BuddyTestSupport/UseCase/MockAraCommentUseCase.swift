//
//  MockAraCommentUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import BuddyDomain

public final class MockAraCommentUseCase: AraCommentUseCaseProtocol, @unchecked Sendable {
  public var writeCommentResult: Result<AraPostComment, Error> = .success(AraPostComment.mock)
  var writeThreadedCommentResult: Result<AraPostComment, Error> = .success(AraPostComment.mock)
  var editCommentResult: Result<AraPostComment, Error> = .success(AraPostComment.mock)
  public var deleteCommentResult: Result<Void, Error> = .success(())
  var upvoteCommentResult: Result<Void, Error> = .success(())
  var downvoteCommentResult: Result<Void, Error> = .success(())
  var cancelVoteResult: Result<Void, Error> = .success(())
  var reportCommentResult: Result<Void, Error> = .success(())

  public init() { }
  
  public func upvoteComment(commentID: Int) async throws {
    try upvoteCommentResult.get()
  }

  public func downvoteComment(commentID: Int) async throws {
    try downvoteCommentResult.get()
  }

  public func cancelVote(commentID: Int) async throws {
    try cancelVoteResult.get()
  }

  public func writeComment(postID: Int, content: String) async throws -> AraPostComment {
    try writeCommentResult.get()
  }

  public func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    try writeThreadedCommentResult.get()
  }

  public func deleteComment(commentID: Int) async throws {
    try deleteCommentResult.get()
  }

  public func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    try editCommentResult.get()
  }

  public func reportComment(commentID: Int, type: AraContentReportType) async throws {
    try reportCommentResult.get()
  }
}
