//
//  FeedCommentRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public actor FeedCommentRepository: FeedCommentRepositoryProtocol {
  private let provider: MoyaProvider<FeedCommentTarget>

  public init(provider: MoyaProvider<FeedCommentTarget>) {
    self.provider = provider
  }

  public func fetchComments(postID: String) async throws -> [FeedComment] {
    let response = try await provider.request(.fetchComments(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
    let comments: [FeedComment] = try response.map([FeedCommentDTO].self).compactMap { $0.toModel()}

    return comments
  }

  public func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    let response = try await provider.request(
      .writeComment(postID: postID, request: FeedCommentRequestDTO.fromModel(request))
    )
    _ = try response.filterSuccessfulStatusCodes()
    let comment: FeedComment = try response.map(FeedCommentDTO.self).toModel()

    return comment
  }

  public func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
    let response = try await provider.request(
      .writeReply(commentID: commentID, request: FeedCommentRequestDTO.fromModel(request))
    )
    _ = try response.filterSuccessfulStatusCodes()
    let comment: FeedComment = try response.map(FeedCommentDTO.self).toModel()

    return comment
  }

  public func deleteComment(commentID: String) async throws {
    let response = try await provider.request(.delete(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func vote(commentID: String, type: FeedVoteType) async throws {
    let response = try await provider.request(.vote(commentID: commentID, type: type))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func deleteVote(commentID: String) async throws {
    let response = try await provider.request(.deleteVote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }
  
  public func reportComment(commentID: String, reason: FeedReportType, detail: String) async throws {
    let response = try await provider.request(.reportComment(commentID: commentID, reason: reason.rawValue, detail: detail))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
