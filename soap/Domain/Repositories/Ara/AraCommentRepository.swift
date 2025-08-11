//
//  AraCommentRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 11/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol AraCommentRepositoryProtocol: Sendable {
  func upvoteComment(commentID: Int) async throws
  func downvoteComment(commentID: Int) async throws
  func cancelVote(commentID: Int) async throws
  func writeComment(postID: Int, content: String) async throws -> AraPostComment
  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment
  func deleteComment(commentID: Int) async throws
  func editComment(commentID: Int, content: String) async throws -> AraPostComment
}

actor AraCommentRepository: AraCommentRepositoryProtocol {
  private let provider: MoyaProvider<AraCommentTarget>

  init(provider: MoyaProvider<AraCommentTarget>) {
    self.provider = provider
  }

  func upvoteComment(commentID: Int) async throws {
    let response = try await provider.request(.upvoteComment(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func downvoteComment(commentID: Int) async throws {
    let response = try await provider.request(.downvoteComment(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func cancelVote(commentID: Int) async throws {
    let response = try await provider.request(.cancelVote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func writeComment(postID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(.writeComment(postID: postID, content: content))
    _ = try response.filterSuccessfulStatusCodes()

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(
      .writeThreadedComment(commentID: commentID, content: content)
    )
    _ = try response.filterSuccessfulStatusCodes()

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }

  func deleteComment(commentID: Int) async throws {
    let response = try await provider.request(.deleteComment(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    let response = try await provider.request(
      .patchComment(commentID: commentID, content: content)
    )
    _ = try response.filterSuccessfulStatusCodes()

    let comment: AraPostComment = try response.map(AraPostCommentDTO.self).toModel()

    return comment
  }
}
