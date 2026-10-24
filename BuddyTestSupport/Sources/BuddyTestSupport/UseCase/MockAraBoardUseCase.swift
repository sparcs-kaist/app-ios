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

  /// The boards `fetchBoards()` returns, or the error it throws.
  public var fetchBoardsResult: Result<[AraBoard], Error> = .success([])
  /// Answers `fetchPosts`; by default an empty page.
  public var fetchPostsHandler: @Sendable (FetchPostsCall) throws -> AraPostPage = { _ in
    AraPostPage(pages: 0, items: 0, currentPage: 0, results: [])
  }
  /// What `writePost` does; it throws until configured, as before.
  public var writePostResult: Result<Void, Error> = .failure(TestError.notConfigured)
  /// What `uploadFile` returns, or the error it throws.
  public var uploadFileResult: Result<AraAttachment, Error> = .failure(TestError.notConfigured)

  /// One `fetchPosts` request, as the use case received it.
  public struct FetchPostsCall: Sendable, Equatable {
    public let type: PostListType
    public let page: Int
    public let pageSize: Int
    public let searchKeyword: String?
  }

  // Requests can arrive from several tasks at once.
  private let lock = NSLock()
  private var _fetchPostsCalls: [FetchPostsCall] = []
  private var _writtenPosts: [AraCreatePost] = []
  private var _uploadedFiles: [(fileName: String, mimeType: String, size: Int)] = []

  public var fetchPostsCalls: [FetchPostsCall] { lock.withLock { _fetchPostsCalls } }
  public var writtenPosts: [AraCreatePost] { lock.withLock { _writtenPosts } }
  public var uploadedFiles: [(fileName: String, mimeType: String, size: Int)] { lock.withLock { _uploadedFiles } }

  public init() { }

  public func fetchBoards() async throws -> [AraBoard] {
    try fetchBoardsResult.get()
  }

  public func fetchPosts(type: PostListType, page: Int, pageSize: Int, searchKeyword: String?) async throws -> AraPostPage {
    let call = FetchPostsCall(type: type, page: page, pageSize: pageSize, searchKeyword: searchKeyword)
    lock.withLock { _fetchPostsCalls.append(call) }
    return try fetchPostsHandler(call)
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

  public func uploadFile(data: Data, fileName: String, mimeType: String) async throws -> AraAttachment {
    lock.withLock { _uploadedFiles.append((fileName, mimeType, data.count)) }
    return try uploadFileResult.get()
  }

  public func writePost(request: AraCreatePost) async throws {
    lock.withLock { _writtenPosts.append(request) }
    try writePostResult.get()
  }

  public func updatePost(postID: Int, request: AraUpdatePost) async throws {
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
