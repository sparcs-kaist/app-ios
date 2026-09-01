//
//  FeedCommentUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import Foundation

public protocol FeedCommentUseCaseProtocol: Sendable {
  func fetchComments(postID: String) async throws -> [FeedComment]
  func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment
  func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment
  func deleteComment(commentID: String) async throws
  func vote(commentID: String, type: FeedVoteType) async throws
  func deleteVote(commentID: String) async throws
  func reportComment(commentID: String, reason: FeedReportType, detail: String) async throws
}
