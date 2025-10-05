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

actor AraCommentRepository: AraCommentRepositoryProtocol {
  private let provider: MoyaProvider<AraCommentTarget>

  init(provider: MoyaProvider<AraCommentTarget>) {
    self.provider = provider
  }

  func upvoteComment(commentID: Int) async throws {
    let response = try await provider.request(.upvote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func downvoteComment(commentID: Int) async throws {
    let response = try await provider.request(.downvote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func cancelVote(commentID: Int) async throws {
    let response = try await provider.request(.cancelVote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func writeComment(postID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(.post(postID: postID, content: content))
    _ = try response.filterSuccessfulStatusCodes()

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(
      .postThreaded(commentID: commentID, content: content)
    )
    _ = try response.filterSuccessfulStatusCodes()

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  func deleteComment(commentID: Int) async throws {
    let response = try await provider.request(.delete(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(
      .patch(commentID: commentID, content: content)
    )
    _ = try response.filterSuccessfulStatusCodes()

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  func reportComment(commentID: Int, type: AraContentReportType) async throws {
    let response = try await provider.request(.report(commentID: commentID, type: type))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
