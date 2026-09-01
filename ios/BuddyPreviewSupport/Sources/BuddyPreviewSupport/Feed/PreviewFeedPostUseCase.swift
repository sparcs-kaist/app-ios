//
//  PreviewFeedPostUseCase.swift
//  BuddyPreviewSupport
//

import Foundation
import BuddyDomain

public struct PreviewFeedPostUseCase: FeedPostUseCaseProtocol {
  public init() {}

  public func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    FeedPostPage(items: FeedPost.mockList, nextCursor: nil, hasNext: false)
  }

  public func writePost(request: FeedCreatePost) async throws {}
  public func deletePost(postID: String) async throws {}
  public func vote(postID: String, type: FeedVoteType) async throws {}
  public func deleteVote(postID: String) async throws {}
  public func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {}
}
