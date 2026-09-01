//
//  MockFeedPostRepository.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation
import BuddyDomain

public final class MockFeedPostRepository: FeedPostRepositoryProtocol, @unchecked Sendable {
  public var fetchPostsResult: Result<FeedPostPage, Error> = .success(FeedPostPage(items: [], nextCursor: nil, hasNext: false))
  public var writePostResult: Result<Void, Error> = .success(())
  public var deletePostResult: Result<Void, Error> = .success(())
  public var voteResult: Result<Void, Error> = .success(())
  public var deleteVoteResult: Result<Void, Error> = .success(())
  public var reportPostResult: Result<Void, Error> = .success(())

  public var fetchPostsCallCount = 0
  public var writePostCallCount = 0
  public var deletePostCallCount = 0
  public var voteCallCount = 0
  public var deleteVoteCallCount = 0
  public var reportPostCallCount = 0

  public var lastCursor: String?
  public var lastPage: Int?
  public var lastWriteRequest: FeedCreatePost?
  public var lastDeletePostID: String?
  public var lastVotePostID: String?
  public var lastVoteType: FeedVoteType?
  public var lastDeleteVotePostID: String?
  public var lastReportPostID: String?
  public var lastReportReason: FeedReportType?
  public var lastReportDetail: String?

  public init() { }

  public func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    fetchPostsCallCount += 1
    lastCursor = cursor
    lastPage = page
    return try fetchPostsResult.get()
  }

  public func writePost(request: FeedCreatePost) async throws {
    writePostCallCount += 1
    lastWriteRequest = request
    try writePostResult.get()
  }

  public func deletePost(postID: String) async throws {
    deletePostCallCount += 1
    lastDeletePostID = postID
    try deletePostResult.get()
  }

  public func vote(postID: String, type: FeedVoteType) async throws {
    voteCallCount += 1
    lastVotePostID = postID
    lastVoteType = type
    try voteResult.get()
  }

  public func deleteVote(postID: String) async throws {
    deleteVoteCallCount += 1
    lastDeleteVotePostID = postID
    try deleteVoteResult.get()
  }

  public func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {
    reportPostCallCount += 1
    lastReportPostID = postID
    lastReportReason = reason
    lastReportDetail = detail
    try reportPostResult.get()
  }
}
