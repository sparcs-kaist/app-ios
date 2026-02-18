//
//  AraCommentRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 11/08/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public actor AraCommentRepository: AraCommentRepositoryProtocol {
  private let provider: MoyaProvider<AraCommentTarget>

  public init(provider: MoyaProvider<AraCommentTarget>) {
    self.provider = provider
  }

  public func upvoteComment(commentID: Int) async throws {
    _ = try await provider.request(.upvote(commentID: commentID))
  }

  public func downvoteComment(commentID: Int) async throws {
    _ = try await provider.request(.downvote(commentID: commentID))
  }

  public func cancelVote(commentID: Int) async throws {
    _ = try await provider.request(.cancelVote(commentID: commentID))
  }

  public func writeComment(postID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(.post(postID: postID, content: content))

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  public func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(
      .postThreaded(commentID: commentID, content: content)
    )

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  public func deleteComment(commentID: Int) async throws {
    _ = try await provider.request(.delete(commentID: commentID))
  }

  public func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(
      .patch(commentID: commentID, content: content)
    )

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  public func reportComment(commentID: Int, type: AraContentReportType) async throws {
    _ = try await provider.request(.report(commentID: commentID, type: type))
  }
}
