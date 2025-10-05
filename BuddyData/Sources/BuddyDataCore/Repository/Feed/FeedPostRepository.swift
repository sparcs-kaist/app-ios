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
    let response = try await provider.request(.writePost(request: FeedPostRequestDTO.fromModel(request)))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func deletePost(postID: String) async throws {
    let response = try await provider.request(.delete(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func vote(postID: String, type: FeedVoteType) async throws {
    let response = try await provider.request(.vote(postID: postID, type: type))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func deleteVote(postID: String) async throws {
    let response = try await provider.request(.deleteVote(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }
  
  public func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {
    let response = try await provider.request(.reportPost(postID: postID, reason: reason.rawValue, detail: detail))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
