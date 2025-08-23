//
//  FeedPostRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol FeedPostRepositoryProtocol: Sendable {
  func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage
  func writePost(request: FeedCreatePost) async throws
  func deletePost(postID: String) async throws
}

actor FeedPostRepository: FeedPostRepositoryProtocol {
  private let provider: MoyaProvider<FeedPostTarget>

  init(provider: MoyaProvider<FeedPostTarget>) {
    self.provider = provider
  }

  func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    let response = try await provider.request(.fetchPosts(cursor: cursor, limit: page))
    let page: FeedPostPage = try response.map(FeedPostPageDTO.self).toModel()

    return page
  }

  func writePost(request: FeedCreatePost) async throws {
    let response = try await provider.request(.writePost(request: FeedPostRequestDTO.fromModel(request)))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func deletePost(postID: String) async throws {
    let response = try await provider.request(.delete(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
