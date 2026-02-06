//
//  BuddyDataTests.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import Foundation
@testable import BuddyDataCore
@testable import BuddyDomain

// MARK: - Mock Repositories

final class MockFeedPostRepository: FeedPostRepositoryProtocol, @unchecked Sendable {
  var fetchPostsResult: Result<FeedPostPage, Error> = .success(FeedPostPage(items: [], nextCursor: nil, hasNext: false))
  var writePostResult: Result<Void, Error> = .success(())
  var deletePostResult: Result<Void, Error> = .success(())
  var voteResult: Result<Void, Error> = .success(())
  var deleteVoteResult: Result<Void, Error> = .success(())
  var reportPostResult: Result<Void, Error> = .success(())

  var fetchPostsCallCount = 0
  var writePostCallCount = 0
  var deletePostCallCount = 0
  var voteCallCount = 0
  var deleteVoteCallCount = 0
  var reportPostCallCount = 0

  var lastCursor: String?
  var lastPage: Int?
  var lastWriteRequest: FeedCreatePost?
  var lastDeletePostID: String?
  var lastVotePostID: String?
  var lastVoteType: FeedVoteType?
  var lastDeleteVotePostID: String?
  var lastReportPostID: String?
  var lastReportReason: FeedReportType?
  var lastReportDetail: String?

  func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    fetchPostsCallCount += 1
    lastCursor = cursor
    lastPage = page
    return try fetchPostsResult.get()
  }

  func writePost(request: FeedCreatePost) async throws {
    writePostCallCount += 1
    lastWriteRequest = request
    try writePostResult.get()
  }

  func deletePost(postID: String) async throws {
    deletePostCallCount += 1
    lastDeletePostID = postID
    try deletePostResult.get()
  }

  func vote(postID: String, type: FeedVoteType) async throws {
    voteCallCount += 1
    lastVotePostID = postID
    lastVoteType = type
    try voteResult.get()
  }

  func deleteVote(postID: String) async throws {
    deleteVoteCallCount += 1
    lastDeleteVotePostID = postID
    try deleteVoteResult.get()
  }

  func reportPost(postID: String, reason: FeedReportType, detail: String) async throws {
    reportPostCallCount += 1
    lastReportPostID = postID
    lastReportReason = reason
    lastReportDetail = detail
    try reportPostResult.get()
  }
}

final class MockFeedCommentRepository: FeedCommentRepositoryProtocol, @unchecked Sendable {
  var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
  var writeCommentResult: Result<FeedComment, Error>?
  var writeReplyResult: Result<FeedComment, Error>?
  var deleteCommentResult: Result<Void, Error> = .success(())
  var voteResult: Result<Void, Error> = .success(())
  var deleteVoteResult: Result<Void, Error> = .success(())
  var reportCommentResult: Result<Void, Error> = .success(())

  var fetchCommentsCallCount = 0
  var writeCommentCallCount = 0
  var writeReplyCallCount = 0
  var deleteCommentCallCount = 0
  var voteCallCount = 0
  var deleteVoteCallCount = 0
  var reportCommentCallCount = 0

  var lastFetchPostID: String?
  var lastWriteCommentPostID: String?
  var lastWriteCommentRequest: FeedCreateComment?
  var lastWriteReplyCommentID: String?
  var lastWriteReplyRequest: FeedCreateComment?
  var lastDeleteCommentID: String?
  var lastVoteCommentID: String?
  var lastVoteType: FeedVoteType?
  var lastDeleteVoteCommentID: String?
  var lastReportCommentID: String?
  var lastReportReason: FeedReportType?
  var lastReportDetail: String?

  func fetchComments(postID: String) async throws -> [FeedComment] {
    fetchCommentsCallCount += 1
    lastFetchPostID = postID
    return try fetchCommentsResult.get()
  }

  func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    writeCommentCallCount += 1
    lastWriteCommentPostID = postID
    lastWriteCommentRequest = request
    guard let result = writeCommentResult else {
      throw TestError.notConfigured
    }
    return try result.get()
  }

  func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
    writeReplyCallCount += 1
    lastWriteReplyCommentID = commentID
    lastWriteReplyRequest = request
    guard let result = writeReplyResult else {
      throw TestError.notConfigured
    }
    return try result.get()
  }

  func deleteComment(commentID: String) async throws {
    deleteCommentCallCount += 1
    lastDeleteCommentID = commentID
    try deleteCommentResult.get()
  }

  func vote(commentID: String, type: FeedVoteType) async throws {
    voteCallCount += 1
    lastVoteCommentID = commentID
    lastVoteType = type
    try voteResult.get()
  }

  func deleteVote(commentID: String) async throws {
    deleteVoteCallCount += 1
    lastDeleteVoteCommentID = commentID
    try deleteVoteResult.get()
  }

  func reportComment(commentID: String, reason: FeedReportType, detail: String) async throws {
    reportCommentCallCount += 1
    lastReportCommentID = commentID
    lastReportReason = reason
    lastReportDetail = detail
    try reportCommentResult.get()
  }
}

final class MockCrashlyticsService: CrashlyticsServiceProtocol, @unchecked Sendable {
  var recordExceptionCallCount = 0
  var recordErrorWithContextCallCount = 0
  var lastRecordedError: Error?
  var lastRecordedContext: CrashContext?

  func recordException(error: Error) {
    recordExceptionCallCount += 1
    lastRecordedError = error
  }

  func record(error: SourcedError, context: CrashContext) {
    recordErrorWithContextCallCount += 1
    lastRecordedError = error
    lastRecordedContext = context
  }

  func record(error: Error, context: CrashContext) {
    recordErrorWithContextCallCount += 1
    lastRecordedError = error
    lastRecordedContext = context
  }
}

// MARK: - Test Helpers

enum TestError: Error, LocalizedError {
  case testFailure
  case notConfigured

  var errorDescription: String? {
    switch self {
    case .testFailure: return "Test failure"
    case .notConfigured: return "Not configured"
    }
  }
}

// MARK: - Test Fixtures

enum UseCaseTestFixtures {
  static func makePost(
    id: String = "post-1",
    content: String = "Test content",
    upvotes: Int = 5,
    downvotes: Int = 2,
    myVote: FeedVoteType? = nil
  ) -> FeedPost {
    FeedPost(
      id: id,
      content: content,
      isAnonymous: false,
      isKaistIP: true,
      authorName: "Test Author",
      nickname: "tester",
      profileImageURL: nil,
      createdAt: Date(),
      commentCount: 0,
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote,
      isAuthor: false,
      images: []
    )
  }

  static func makeComment(
    id: String = "comment-1",
    postID: String = "post-1",
    parentCommentID: String? = nil,
    content: String = "Test comment"
  ) -> FeedComment {
    FeedComment(
      id: id,
      postID: postID,
      parentCommentID: parentCommentID,
      content: content,
      isDeleted: false,
      isAnonymous: false,
      isKaistIP: true,
      authorName: "Test Commenter",
      isAuthor: false,
      isMyComment: false,
      profileImageURL: nil,
      createdAt: Date(),
      upvotes: 3,
      downvotes: 1,
      myVote: nil,
      image: nil,
      replyCount: 0,
      replies: []
    )
  }

  static func makePostPage(
    posts: [FeedPost] = [],
    nextCursor: String? = nil,
    hasNext: Bool = false
  ) -> FeedPostPage {
    FeedPostPage(items: posts, nextCursor: nextCursor, hasNext: hasNext)
  }

  static func makeCreatePost(
    content: String = "New post content",
    isAnonymous: Bool = false,
    images: [FeedImage] = []
  ) -> FeedCreatePost {
    FeedCreatePost(content: content, isAnonymous: isAnonymous, images: images)
  }

  static func makeCreateComment(
    content: String = "New comment",
    isAnonymous: Bool = false,
    image: FeedImage? = nil
  ) -> FeedCreateComment {
    FeedCreateComment(content: content, isAnonymous: isAnonymous, image: image)
  }
}

// MARK: - FeedPostUseCase Tests

@Suite("FeedPostUseCase Tests")
struct FeedPostUseCaseTests {

  @Test("fetchPosts delegates to repository with correct parameters")
  func fetchPostsDelegatesToRepository() async throws {
    let mockRepo = MockFeedPostRepository()
    let posts = [UseCaseTestFixtures.makePost(id: "1"), UseCaseTestFixtures.makePost(id: "2")]
    mockRepo.fetchPostsResult = .success(UseCaseTestFixtures.makePostPage(posts: posts, nextCursor: "next", hasNext: true))

    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    let result = try await useCase.fetchPosts(cursor: "cursor-1", page: 20)

    #expect(mockRepo.fetchPostsCallCount == 1)
    #expect(mockRepo.lastCursor == "cursor-1")
    #expect(mockRepo.lastPage == 20)
    #expect(result.items.count == 2)
    #expect(result.nextCursor == "next")
    #expect(result.hasNext == true)
  }

  @Test("fetchPosts with nil cursor")
  func fetchPostsWithNilCursor() async throws {
    let mockRepo = MockFeedPostRepository()
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    _ = try await useCase.fetchPosts(cursor: nil, page: 10)

    #expect(mockRepo.lastCursor == nil)
    #expect(mockRepo.lastPage == 10)
  }

  @Test("writePost delegates to repository")
  func writePostDelegatesToRepository() async throws {
    let mockRepo = MockFeedPostRepository()
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    let request = UseCaseTestFixtures.makeCreatePost(content: "Hello world", isAnonymous: true)
    try await useCase.writePost(request: request)

    #expect(mockRepo.writePostCallCount == 1)
    #expect(mockRepo.lastWriteRequest?.content == "Hello world")
    #expect(mockRepo.lastWriteRequest?.isAnonymous == true)
  }

  @Test("deletePost delegates to repository")
  func deletePostDelegatesToRepository() async throws {
    let mockRepo = MockFeedPostRepository()
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    try await useCase.deletePost(postID: "post-123")

    #expect(mockRepo.deletePostCallCount == 1)
    #expect(mockRepo.lastDeletePostID == "post-123")
  }

  @Test("deletePost with 409 error throws cannotDeletePostWithVoteOrComment")
  func deletePost409Error() async {
    let mockRepo = MockFeedPostRepository()
    mockRepo.deletePostResult = .failure(NetworkError.serverError(statusCode: 409))
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    do {
      try await useCase.deletePost(postID: "post-123")
      Issue.record("Expected error to be thrown")
    } catch let error as FeedPostUseCaseError {
      if case .cannotDeletePostWithVoteOrComment = error {
        // Expected
      } else {
        Issue.record("Expected cannotDeletePostWithVoteOrComment error")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("deletePost with other NetworkError propagates and records to Crashlytics")
  func deletePostNetworkErrorRecordsCrashlytics() async {
    let mockRepo = MockFeedPostRepository()
    let mockCrashlytics = MockCrashlyticsService()
    mockRepo.deletePostResult = .failure(NetworkError.serverError(statusCode: 500))
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: mockCrashlytics)

    do {
      try await useCase.deletePost(postID: "post-123")
      Issue.record("Expected error to be thrown")
    } catch {
      #expect(mockCrashlytics.recordErrorWithContextCallCount == 1)
      #expect(mockCrashlytics.lastRecordedContext?.feature == "FeedPost")
    }
  }

  @Test("vote delegates to repository with correct parameters")
  func voteDelegatesToRepository() async throws {
    let mockRepo = MockFeedPostRepository()
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    try await useCase.vote(postID: "post-1", type: .up)

    #expect(mockRepo.voteCallCount == 1)
    #expect(mockRepo.lastVotePostID == "post-1")
    #expect(mockRepo.lastVoteType == .up)
  }

  @Test("deleteVote delegates to repository")
  func deleteVoteDelegatesToRepository() async throws {
    let mockRepo = MockFeedPostRepository()
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    try await useCase.deleteVote(postID: "post-1")

    #expect(mockRepo.deleteVoteCallCount == 1)
    #expect(mockRepo.lastDeleteVotePostID == "post-1")
  }

  @Test("reportPost delegates to repository with all parameters")
  func reportPostDelegatesToRepository() async throws {
    let mockRepo = MockFeedPostRepository()
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: nil)

    try await useCase.reportPost(postID: "post-1", reason: .spam, detail: "This is spam")

    #expect(mockRepo.reportPostCallCount == 1)
    #expect(mockRepo.lastReportPostID == "post-1")
    #expect(mockRepo.lastReportReason == .spam)
    #expect(mockRepo.lastReportDetail == "This is spam")
  }

  @Test("unknown error is wrapped and recorded to Crashlytics")
  func unknownErrorWrappedAndRecorded() async {
    let mockRepo = MockFeedPostRepository()
    let mockCrashlytics = MockCrashlyticsService()
    mockRepo.fetchPostsResult = .failure(TestError.testFailure)
    let useCase = FeedPostUseCase(feedPostRepository: mockRepo, crashlyticsService: mockCrashlytics)

    do {
      _ = try await useCase.fetchPosts(cursor: nil, page: 20)
      Issue.record("Expected error to be thrown")
    } catch let error as FeedPostUseCaseError {
      if case .unknown(let underlying) = error {
        #expect(underlying != nil)
      } else {
        Issue.record("Expected unknown error")
      }
      #expect(mockCrashlytics.recordErrorWithContextCallCount == 1)
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - FeedCommentUseCase Tests

@Suite("FeedCommentUseCase Tests")
struct FeedCommentUseCaseTests {

  @Test("fetchComments delegates to repository")
  func fetchCommentsDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let comments = [UseCaseTestFixtures.makeComment(id: "1"), UseCaseTestFixtures.makeComment(id: "2")]
    mockRepo.fetchCommentsResult = .success(comments)

    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    let result = try await useCase.fetchComments(postID: "post-1")

    #expect(mockRepo.fetchCommentsCallCount == 1)
    #expect(mockRepo.lastFetchPostID == "post-1")
    #expect(result.count == 2)
  }

  @Test("writeComment delegates to repository")
  func writeCommentDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let expectedComment = UseCaseTestFixtures.makeComment(id: "new-comment")
    mockRepo.writeCommentResult = .success(expectedComment)

    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)
    let request = UseCaseTestFixtures.makeCreateComment(content: "Hello", isAnonymous: true)

    let result = try await useCase.writeComment(postID: "post-1", request: request)

    #expect(mockRepo.writeCommentCallCount == 1)
    #expect(mockRepo.lastWriteCommentPostID == "post-1")
    #expect(mockRepo.lastWriteCommentRequest?.content == "Hello")
    #expect(mockRepo.lastWriteCommentRequest?.isAnonymous == true)
    #expect(result.id == "new-comment")
  }

  @Test("writeReply delegates to repository")
  func writeReplyDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let expectedReply = UseCaseTestFixtures.makeComment(id: "reply-1", parentCommentID: "comment-1")
    mockRepo.writeReplyResult = .success(expectedReply)

    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)
    let request = UseCaseTestFixtures.makeCreateComment(content: "Reply content")

    let result = try await useCase.writeReply(commentID: "comment-1", request: request)

    #expect(mockRepo.writeReplyCallCount == 1)
    #expect(mockRepo.lastWriteReplyCommentID == "comment-1")
    #expect(result.id == "reply-1")
  }

  @Test("deleteComment delegates to repository")
  func deleteCommentDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    try await useCase.deleteComment(commentID: "comment-123")

    #expect(mockRepo.deleteCommentCallCount == 1)
    #expect(mockRepo.lastDeleteCommentID == "comment-123")
  }

  @Test("deleteComment with 409 error throws cannotDeleteCommentWithVote")
  func deleteComment409Error() async {
    let mockRepo = MockFeedCommentRepository()
    mockRepo.deleteCommentResult = .failure(NetworkError.serverError(statusCode: 409))
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    do {
      try await useCase.deleteComment(commentID: "comment-123")
      Issue.record("Expected error to be thrown")
    } catch let error as FeedCommentUseCaseError {
      if case .cannotDeleteCommentWithVote = error {
        // Expected
      } else {
        Issue.record("Expected cannotDeleteCommentWithVote error")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("vote delegates to repository")
  func voteDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    try await useCase.vote(commentID: "comment-1", type: .down)

    #expect(mockRepo.voteCallCount == 1)
    #expect(mockRepo.lastVoteCommentID == "comment-1")
    #expect(mockRepo.lastVoteType == .down)
  }

  @Test("deleteVote delegates to repository")
  func deleteVoteDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    try await useCase.deleteVote(commentID: "comment-1")

    #expect(mockRepo.deleteVoteCallCount == 1)
    #expect(mockRepo.lastDeleteVoteCommentID == "comment-1")
  }

  @Test("reportComment delegates to repository")
  func reportCommentDelegatesToRepository() async throws {
    let mockRepo = MockFeedCommentRepository()
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    try await useCase.reportComment(commentID: "comment-1", reason: .abusiveLanguage, detail: "Offensive")

    #expect(mockRepo.reportCommentCallCount == 1)
    #expect(mockRepo.lastReportCommentID == "comment-1")
    #expect(mockRepo.lastReportReason == .abusiveLanguage)
    #expect(mockRepo.lastReportDetail == "Offensive")
  }

  @Test("NetworkError is recorded to Crashlytics")
  func networkErrorRecordsCrashlytics() async {
    let mockRepo = MockFeedCommentRepository()
    let mockCrashlytics = MockCrashlyticsService()
    mockRepo.voteResult = .failure(NetworkError.serverError(statusCode: 500))
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: mockCrashlytics)

    do {
      try await useCase.vote(commentID: "comment-1", type: .up)
      Issue.record("Expected error to be thrown")
    } catch {
      #expect(mockCrashlytics.recordErrorWithContextCallCount == 1)
      #expect(mockCrashlytics.lastRecordedContext?.feature == "FeedComment")
    }
  }

  @Test("unknown error is wrapped in FeedCommentUseCaseError.unknown")
  func unknownErrorWrapped() async {
    let mockRepo = MockFeedCommentRepository()
    mockRepo.fetchCommentsResult = .failure(TestError.testFailure)
    let useCase = FeedCommentUseCase(feedCommentRepository: mockRepo, crashlyticsService: nil)

    do {
      _ = try await useCase.fetchComments(postID: "post-1")
      Issue.record("Expected error to be thrown")
    } catch let error as FeedCommentUseCaseError {
      if case .unknown(let underlying) = error {
        #expect(underlying != nil)
      } else {
        Issue.record("Expected unknown error")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
