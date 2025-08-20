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
}
