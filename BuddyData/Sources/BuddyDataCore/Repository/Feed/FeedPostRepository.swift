//
//  FeedPostRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public actor FeedPostRepository: FeedPostRepositoryProtocol {
  private let provider: MoyaProvider<FeedPostTarget>

  public init(provider: MoyaProvider<FeedPostTarget>) {
    self.provider = provider
  }

  public func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    let response = try await provider.request(.fetchPosts(cursor: cursor, limit: page))
    let page: FeedPostPage = try response.map(FeedPostPageDTO.self).toModel()

    return page
  }

  public func writePost(request: FeedCreatePost) async throws {
    _ = try await provider.request(.writePost(request: FeedPostRequestDTO.fromModel(request)))
  }

  public func deletePost(postID: String) async throws {
    _ = try await provider.request(.delete(postID: postID))
  }

  public func vote(postID: String, type: FeedVoteType) async throws {
    _ = try await provider.request(.vote(postID: postID, type: type))
  }

  public func deleteVote(postID: String) async throws {
    _ = try await provider.request(.deleteVote(postID: postID))
  }
  
  public func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {
    _ = try await provider.request(.reportPost(postID: postID, reason: reason.rawValue, detail: detail))
  }
}
