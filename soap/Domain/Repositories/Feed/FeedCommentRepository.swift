//
//  FeedCommentRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol FeedCommentRepositoryProtocol: Sendable {
  func fetchComments(postID: String) async throws -> [FeedComment]
  func writeComment(postID: String, request: FeedCreateComment) async throws
  func writeReply(commentID: String, request: FeedCreateComment) async throws
  func deleteComment(commentID: String) async throws
  func vote(commentID: String, type: FeedVoteType) async throws
  func deleteVote(commentID: String) async throws
}

actor FeedCommentRepository: FeedCommentRepositoryProtocol {
  private let provider: MoyaProvider<FeedCommentTarget>

  init(provider: MoyaProvider<FeedCommentTarget>) {
    self.provider = provider
  }

  func fetchComments(postID: String) async throws -> [FeedComment] {
    let response = try await provider.request(.fetchComments(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
    let comments: [FeedComment] = try response.map([FeedCommentDTO].self).compactMap { $0.toModel()}

    return comments
  }

  func writeComment(postID: String, request: FeedCreateComment) async throws {
    let response = try await provider.request(
      .writeComment(postID: postID, request: FeedCommentRequestDTO.fromModel(request))
    )
    _ = try response.filterSuccessfulStatusCodes()
  }

  func writeReply(commentID: String, request: FeedCreateComment) async throws {
    let response = try await provider.request(
      .writeReply(commentID: commentID, request: FeedCommentRequestDTO.fromModel(request))
    )
    _ = try response.filterSuccessfulStatusCodes()
  }

  func deleteComment(commentID: String) async throws {
    let response = try await provider.request(.delete(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func vote(commentID: String, type: FeedVoteType) async throws {
    let response = try await provider.request(.vote(commentID: commentID, type: type))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func deleteVote(commentID: String) async throws {
    let response = try await provider.request(.deleteVote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
