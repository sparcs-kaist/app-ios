//
//  PreviewFeedCommentUseCase.swift
//  BuddyPreviewSupport
//

import Foundation
import BuddyDomain

public struct PreviewFeedCommentUseCase: FeedCommentUseCaseProtocol {
  public init() {}

  public func fetchComments(postID: String) async throws -> [FeedComment] {
    FeedComment.mockList
  }

  public func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    FeedComment.mock
  }

  public func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
    FeedComment.mock
  }

  public func deleteComment(commentID: String) async throws {}
  public func vote(commentID: String, type: FeedVoteType) async throws {}
  public func deleteVote(commentID: String) async throws {}
  public func reportComment(commentID: String, reason: FeedReportType, detail: String) async throws {}
}
