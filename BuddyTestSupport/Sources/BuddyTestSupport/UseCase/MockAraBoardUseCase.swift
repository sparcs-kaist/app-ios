//
//  MockAraBoardUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import UIKit
import BuddyDomain

public final class MockAraBoardUseCase: AraBoardUseCaseProtocol, @unchecked Sendable {
  public var fetchPostResult: Result<AraPost, Error> = .success(AraPost.mock)
  var deletePostResult: Result<Void, Error> = .success(())
  var reportPostResult: Result<Void, Error> = .success(())
  var upvotePostResult: Result<Void, Error> = .success(())
  var downvotePostResult: Result<Void, Error> = .success(())
  var cancelVoteResult: Result<Void, Error> = .success(())
  var addBookmarkResult: Result<Void, Error> = .success(())
  var removeBookmarkResult: Result<Void, Error> = .success(())

  public var fetchPostCallCount: Int = 0
  public var lastFetchPostID: Int?
  public var deletePostCallCount: Int = 0
  public var reportPostCallCount: Int = 0

  public init() { }

  public func fetchBoards() async throws -> [AraBoard] { [] }
  public func fetchPosts(type: PostListType, page: Int, pageSize: Int, searchKeyword: String?) async throws -> AraPostPage {
    AraPostPage(pages: 0, items: 0, currentPage: 0, results: [])
  }

  public func fetchPost(origin: PostOrigin?, postID: Int) async throws -> AraPost {
    fetchPostCallCount += 1
    lastFetchPostID = postID
    return try fetchPostResult.get()
  }

  public func fetchBookmarks(page: Int, pageSize: Int) async throws -> AraPostPage {
    AraPostPage(pages: 0, items: 0, currentPage: 0, results: [])
  }

  public func uploadImage(image: UIImage) async throws -> AraAttachment {
    throw TestError.notConfigured
  }

  public func writePost(request: AraCreatePost) async throws {
    throw TestError.notConfigured
  }

  public func upvotePost(postID: Int) async throws {
    try upvotePostResult.get()
  }

  public func downvotePost(postID: Int) async throws {
    try downvotePostResult.get()
  }

  public func cancelVote(postID: Int) async throws {
    try cancelVoteResult.get()
  }

  public func reportPost(postID: Int, type: AraContentReportType) async throws {
    reportPostCallCount += 1
    try reportPostResult.get()
  }

  public func deletePost(postID: Int) async throws {
    deletePostCallCount += 1
    try deletePostResult.get()
  }

  public func addBookmark(postID: Int) async throws {
    try addBookmarkResult.get()
  }

  public func removeBookmark(bookmarkID: Int) async throws {
    try removeBookmarkResult.get()
  }
}
