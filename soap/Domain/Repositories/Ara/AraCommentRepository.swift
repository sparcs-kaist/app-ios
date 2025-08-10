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
  func cancleVote(commentID: Int) async throws
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

  func cancleVote(commentID: Int) async throws {
    let response = try await provider.request(.cancelVote(commentID: commentID))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
