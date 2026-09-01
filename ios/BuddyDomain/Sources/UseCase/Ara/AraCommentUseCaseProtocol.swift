//
//  AraCommentUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation

public protocol AraCommentUseCaseProtocol: Sendable {
  func upvoteComment(commentID: Int) async throws
  func downvoteComment(commentID: Int) async throws
  func cancelVote(commentID: Int) async throws
  func writeComment(postID: Int, content: String) async throws -> AraPostComment
  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment
  func deleteComment(commentID: Int) async throws
  func editComment(commentID: Int, content: String) async throws -> AraPostComment
  func reportComment(commentID: Int, type: AraContentReportType) async throws
}
