//
//  BuddyFeatureFeedTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import SwiftUI
import Factory
@testable import BuddyFeatureFeed
@testable import BuddyDomain

// MARK: - Mock UseCases

final class MockFeedPostUseCase: FeedPostUseCaseProtocol, @unchecked Sendable {
  var fetchPostsResult: Result<FeedPostPage, Error> = .success(FeedPostPage(items: [], nextCursor: nil, hasNext: false))
  var deletePostResult: Result<Void, Error> = .success(())
  var voteResult: Result<Void, Error> = .success(())
  var deleteVoteResult: Result<Void, Error> = .success(())
  var reportPostResult: Result<Void, Error> = .success(())
  var writePostResult: Result<Void, Error> = .success(())

  var fetchPostsCallCount = 0
  var deletePostCallCount = 0
  var voteCallCount = 0
  var deleteVoteCallCount = 0
  var reportPostCallCount = 0

  var lastVotePostID: String?
  var lastVoteType: FeedVoteType?
  var lastDeleteVotePostID: String?
  var lastDeletePostID: String?
  var lastReportPostID: String?
  var lastReportReason: FeedReportType?

  func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage {
    fetchPostsCallCount += 1
    return try fetchPostsResult.get()
  }

  func writePost(request: FeedCreatePost) async throws {
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
    try reportPostResult.get()
  }
}

final class MockFeedCommentUseCase: FeedCommentUseCaseProtocol, @unchecked Sendable {
  var fetchCommentsResult: Result<[FeedComment], Error> = .success([])
  var writeCommentResult: Result<FeedComment, Error>?
  var writeReplyResult: Result<FeedComment, Error>?
  var deleteCommentResult: Result<Void, Error> = .success(())
  var voteResult: Result<Void, Error> = .success(())
  var deleteVoteResult: Result<Void, Error> = .success(())
  var reportCommentResult: Result<Void, Error> = .success(())

  var voteCallCount = 0
  var deleteVoteCallCount = 0
  var deleteCommentCallCount = 0
  var reportCommentCallCount = 0

  var lastVoteCommentID: String?
  var lastVoteType: FeedVoteType?
  var lastDeleteVoteCommentID: String?
  var lastDeleteCommentID: String?
  var lastReportCommentID: String?
  var lastReportReason: FeedReportType?

  func fetchComments(postID: String) async throws -> [FeedComment] {
    try fetchCommentsResult.get()
  }

  func writeComment(postID: String, request: FeedCreateComment) async throws -> FeedComment {
    guard let result = writeCommentResult else {
      throw TestError.notConfigured
    }
    return try result.get()
  }

  func writeReply(commentID: String, request: FeedCreateComment) async throws -> FeedComment {
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
    try reportCommentResult.get()
  }
}

final class MockAuthUseCase: AuthUseCaseProtocol, @unchecked Sendable {
  var signOutResult: Result<Void, Error> = .success(())
  var signOutCallCount = 0

  nonisolated var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    Just(true).eraseToAnyPublisher()
  }

  func signIn() async throws {}
  func signOut() async throws {
    signOutCallCount += 1
    try signOutResult.get()
  }
  func getAccessToken() -> String? { nil }
  func getValidAccessToken() async throws -> String { "" }
  func refreshAccessToken(force: Bool) async throws {}
}

final class MockCrashlyticsService: CrashlyticsServiceProtocol, @unchecked Sendable {
  func recordException(error: Error) {}
  func record(error: SourcedError, context: CrashContext) {}
  func record(error: Error, context: CrashContext) {}
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

import Combine

// MARK: - Test Fixtures

enum FeedTestFixtures {
  static func makePost(
    id: String = "post-1",
    content: String = "Test content",
    upvotes: Int = 5,
    downvotes: Int = 2,
    myVote: FeedVoteType? = nil,
    commentCount: Int = 0,
    isAuthor: Bool = false
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
      commentCount: commentCount,
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote,
      isAuthor: isAuthor,
      images: []
    )
  }

  static func makeComment(
    id: String = "comment-1",
    postID: String = "post-1",
    parentCommentID: String? = nil,
    content: String = "Test comment",
    upvotes: Int = 3,
    downvotes: Int = 1,
    myVote: FeedVoteType? = nil,
    isDeleted: Bool = false,
    isAuthor: Bool = false,
    replies: [FeedComment] = []
  ) -> FeedComment {
    FeedComment(
      id: id,
      postID: postID,
      parentCommentID: parentCommentID,
      content: content,
      isDeleted: isDeleted,
      isAnonymous: false,
      isKaistIP: true,
      authorName: "Test Commenter",
      isAuthor: isAuthor,
      isMyComment: isAuthor,
      profileImageURL: nil,
      createdAt: Date(),
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote,
      image: nil,
      replyCount: replies.count,
      replies: replies
    )
  }

  static func makePostPage(
    posts: [FeedPost] = [],
    nextCursor: String? = nil,
    hasNext: Bool = false
  ) -> FeedPostPage {
    FeedPostPage(items: posts, nextCursor: nextCursor, hasNext: hasNext)
  }
}

// MARK: - Test Setup Helpers

/// Registers all required dependencies for Feed tests and returns cleanup function
@MainActor
func setupFeedTestDependencies(
  feedPostUseCase: MockFeedPostUseCase? = nil,
  feedCommentUseCase: MockFeedCommentUseCase? = nil,
  authUseCase: MockAuthUseCase? = nil
) {
  // Always register crashlytics service (required by ViewModels)
  Container.shared.crashlyticsService.register { MockCrashlyticsService() }

  // Register provided mocks, or default mocks for promised factories
  Container.shared.feedPostUseCase.register { feedPostUseCase ?? MockFeedPostUseCase() }
  Container.shared.feedCommentUseCase.register { feedCommentUseCase ?? MockFeedCommentUseCase() }
  Container.shared.authUseCase.register { authUseCase ?? MockAuthUseCase() }
}

@MainActor
func tearDownFeedTestDependencies() {
  Container.shared.feedPostUseCase.reset()
  Container.shared.feedCommentUseCase.reset()
  Container.shared.authUseCase.reset()
  Container.shared.crashlyticsService.reset()
}

// MARK: - FeedPostRowViewModel Tests

@Suite("FeedPostRowViewModel Tests")
struct FeedPostRowViewModelTests {

  // MARK: - Upvote Tests

  @Test("Upvote from no vote increments upvotes and sets myVote to up")
  @MainActor
  func upvoteFromNoVote() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 2, myVote: nil)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.upvote(post: binding)

    #expect(post.myVote == .up)
    #expect(post.upvotes == 6)
    #expect(post.downvotes == 2)
    #expect(mockUseCase.voteCallCount == 1)
    #expect(mockUseCase.lastVoteType == .up)

    tearDownFeedTestDependencies()
  }

  @Test("Upvote when already upvoted cancels vote")
  @MainActor
  func upvoteCancelsExistingUpvote() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 2, myVote: .up)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.upvote(post: binding)

    #expect(post.myVote == nil)
    #expect(post.upvotes == 4)
    #expect(post.downvotes == 2)
    #expect(mockUseCase.deleteVoteCallCount == 1)

    tearDownFeedTestDependencies()
  }

  @Test("Upvote when downvoted switches to upvote")
  @MainActor
  func upvoteSwitchesFromDownvote() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 3, myVote: .down)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.upvote(post: binding)

    #expect(post.myVote == .up)
    #expect(post.upvotes == 6)
    #expect(post.downvotes == 2)
    #expect(mockUseCase.voteCallCount == 1)
    #expect(mockUseCase.lastVoteType == .up)

    tearDownFeedTestDependencies()
  }

  @Test("Upvote error rolls back state and shows alert")
  @MainActor
  func upvoteErrorRollback() async {
    let mockUseCase = MockFeedPostUseCase()
    mockUseCase.voteResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 2, myVote: nil)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.upvote(post: binding)

    #expect(post.myVote == nil)
    #expect(post.upvotes == 5)
    #expect(post.downvotes == 2)
    #expect(viewModel.isAlertPresented == true)
    #expect(viewModel.alertState != nil)

    tearDownFeedTestDependencies()
  }

  // MARK: - Downvote Tests

  @Test("Downvote from no vote increments downvotes and sets myVote to down")
  @MainActor
  func downvoteFromNoVote() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 2, myVote: nil)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.downvote(post: binding)

    #expect(post.myVote == .down)
    #expect(post.upvotes == 5)
    #expect(post.downvotes == 3)
    #expect(mockUseCase.voteCallCount == 1)
    #expect(mockUseCase.lastVoteType == .down)

    tearDownFeedTestDependencies()
  }

  @Test("Downvote when already downvoted cancels vote")
  @MainActor
  func downvoteCancelsExistingDownvote() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 3, myVote: .down)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.downvote(post: binding)

    #expect(post.myVote == nil)
    #expect(post.upvotes == 5)
    #expect(post.downvotes == 2)
    #expect(mockUseCase.deleteVoteCallCount == 1)

    tearDownFeedTestDependencies()
  }

  @Test("Downvote when upvoted switches to downvote")
  @MainActor
  func downvoteSwitchesFromUpvote() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 6, downvotes: 2, myVote: .up)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.downvote(post: binding)

    #expect(post.myVote == .down)
    #expect(post.upvotes == 5)
    #expect(post.downvotes == 3)
    #expect(mockUseCase.voteCallCount == 1)
    #expect(mockUseCase.lastVoteType == .down)

    tearDownFeedTestDependencies()
  }

  @Test("Downvote error rolls back state and shows alert")
  @MainActor
  func downvoteErrorRollback() async {
    let mockUseCase = MockFeedPostUseCase()
    mockUseCase.voteResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    var post = FeedTestFixtures.makePost(upvotes: 5, downvotes: 2, myVote: nil)
    let binding = Binding(get: { post }, set: { post = $0 })

    await viewModel.downvote(post: binding)

    #expect(post.myVote == nil)
    #expect(post.upvotes == 5)
    #expect(post.downvotes == 2)
    #expect(viewModel.isAlertPresented == true)
    #expect(viewModel.alertState != nil)

    tearDownFeedTestDependencies()
  }

  // MARK: - Report Tests

  @Test("Report post succeeds and shows success alert")
  @MainActor
  func reportPostSuccess() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    await viewModel.reportPost(postID: "post-1", reason: .spam)

    #expect(mockUseCase.reportPostCallCount == 1)
    #expect(mockUseCase.lastReportPostID == "post-1")
    #expect(mockUseCase.lastReportReason == .spam)
    #expect(viewModel.isAlertPresented == true)

    tearDownFeedTestDependencies()
  }

  @Test("Report post error shows error alert")
  @MainActor
  func reportPostError() async {
    let mockUseCase = MockFeedPostUseCase()
    mockUseCase.reportPostResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedPostRowViewModel()

    await viewModel.reportPost(postID: "post-1", reason: .spam)

    #expect(viewModel.isAlertPresented == true)
    #expect(viewModel.alertState != nil)

    tearDownFeedTestDependencies()
  }
}

// MARK: - FeedCommentRowViewModel Tests

@Suite("FeedCommentRowViewModel Tests")
struct FeedCommentRowViewModelTests {

  // MARK: - Upvote Tests

  @Test("Upvote comment from no vote increments upvotes")
  @MainActor
  func upvoteCommentFromNoVote() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(upvotes: 3, downvotes: 1, myVote: nil)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.upvote(comment: binding)

    #expect(comment.myVote == .up)
    #expect(comment.upvotes == 4)
    #expect(comment.downvotes == 1)
    #expect(mockUseCase.voteCallCount == 1)
    #expect(mockUseCase.lastVoteType == .up)

    tearDownFeedTestDependencies()
  }

  @Test("Upvote comment cancels when already upvoted")
  @MainActor
  func upvoteCommentCancelsExisting() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(upvotes: 4, downvotes: 1, myVote: .up)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.upvote(comment: binding)

    #expect(comment.myVote == nil)
    #expect(comment.upvotes == 3)
    #expect(mockUseCase.deleteVoteCallCount == 1)

    tearDownFeedTestDependencies()
  }

  @Test("Upvote comment switches from downvote")
  @MainActor
  func upvoteCommentSwitchesFromDownvote() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(upvotes: 3, downvotes: 2, myVote: .down)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.upvote(comment: binding)

    #expect(comment.myVote == .up)
    #expect(comment.upvotes == 4)
    #expect(comment.downvotes == 1)

    tearDownFeedTestDependencies()
  }

  @Test("Upvote comment error rolls back all values")
  @MainActor
  func upvoteCommentErrorRollback() async {
    let mockUseCase = MockFeedCommentUseCase()
    mockUseCase.voteResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(upvotes: 3, downvotes: 1, myVote: nil)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.upvote(comment: binding)

    #expect(comment.myVote == nil)
    #expect(comment.upvotes == 3)
    #expect(comment.downvotes == 1)
    #expect(viewModel.isAlertPresented == true)

    tearDownFeedTestDependencies()
  }

  // MARK: - Downvote Tests

  @Test("Downvote comment from no vote increments downvotes")
  @MainActor
  func downvoteCommentFromNoVote() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(upvotes: 3, downvotes: 1, myVote: nil)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.downvote(comment: binding)

    #expect(comment.myVote == .down)
    #expect(comment.upvotes == 3)
    #expect(comment.downvotes == 2)
    #expect(mockUseCase.voteCallCount == 1)
    #expect(mockUseCase.lastVoteType == .down)

    tearDownFeedTestDependencies()
  }

  @Test("Downvote comment cancels when already downvoted")
  @MainActor
  func downvoteCommentCancelsExisting() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(upvotes: 3, downvotes: 2, myVote: .down)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.downvote(comment: binding)

    #expect(comment.myVote == nil)
    #expect(comment.downvotes == 1)
    #expect(mockUseCase.deleteVoteCallCount == 1)

    tearDownFeedTestDependencies()
  }

  // MARK: - Delete Tests

  @Test("Delete comment sets isDeleted optimistically")
  @MainActor
  func deleteCommentOptimistic() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(isDeleted: false)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.delete(comment: binding)

    #expect(comment.isDeleted == true)
    #expect(mockUseCase.deleteCommentCallCount == 1)
    #expect(mockUseCase.lastDeleteCommentID == comment.id)

    tearDownFeedTestDependencies()
  }

  @Test("Delete comment error rolls back isDeleted flag")
  @MainActor
  func deleteCommentErrorRollback() async {
    let mockUseCase = MockFeedCommentUseCase()
    mockUseCase.deleteCommentResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    var comment = FeedTestFixtures.makeComment(isDeleted: false)
    let binding = Binding(get: { comment }, set: { comment = $0 })

    await viewModel.delete(comment: binding)

    #expect(comment.isDeleted == false)
    #expect(viewModel.isAlertPresented == true)

    tearDownFeedTestDependencies()
  }

  // MARK: - Report Tests

  @Test("Report comment succeeds and shows success alert")
  @MainActor
  func reportCommentSuccess() async {
    let mockUseCase = MockFeedCommentUseCase()
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    await viewModel.reportComment(commentID: "comment-1", reason: .abusiveLanguage)

    #expect(mockUseCase.reportCommentCallCount == 1)
    #expect(mockUseCase.lastReportCommentID == "comment-1")
    #expect(mockUseCase.lastReportReason == .abusiveLanguage)
    #expect(viewModel.isAlertPresented == true)

    tearDownFeedTestDependencies()
  }

  @Test("Report comment error shows error alert")
  @MainActor
  func reportCommentError() async {
    let mockUseCase = MockFeedCommentUseCase()
    mockUseCase.reportCommentResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedCommentUseCase: mockUseCase)

    let viewModel = FeedCommentRowViewModel()

    await viewModel.reportComment(commentID: "comment-1", reason: .spam)

    #expect(viewModel.isAlertPresented == true)
    #expect(viewModel.alertState != nil)

    tearDownFeedTestDependencies()
  }
}

// MARK: - FeedViewModel Tests

@Suite("FeedViewModel Tests")
struct FeedViewModelTests {

  @Test("Initial state is loading")
  @MainActor
  func initialStateIsLoading() {
    let viewModel = FeedViewModel()
    #expect(viewModel.state == .loading)
    #expect(viewModel.posts.isEmpty)
  }

  @Test("fetchInitialData loads posts and sets state to loaded")
  @MainActor
  func fetchInitialDataSuccess() async {
    let mockUseCase = MockFeedPostUseCase()
    let posts = [
      FeedTestFixtures.makePost(id: "1"),
      FeedTestFixtures.makePost(id: "2")
    ]
    mockUseCase.fetchPostsResult = .success(FeedTestFixtures.makePostPage(
      posts: posts,
      nextCursor: "cursor-1",
      hasNext: true
    ))
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedViewModel()

    await viewModel.fetchInitialData()

    #expect(viewModel.state == .loaded)
    #expect(viewModel.posts.count == 2)
    #expect(viewModel.posts[0].id == "1")
    #expect(viewModel.posts[1].id == "2")
    #expect(mockUseCase.fetchPostsCallCount == 1)

    tearDownFeedTestDependencies()
  }

  @Test("fetchInitialData error sets state to error")
  @MainActor
  func fetchInitialDataError() async {
    let mockUseCase = MockFeedPostUseCase()
    mockUseCase.fetchPostsResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedViewModel()

    await viewModel.fetchInitialData()

    if case .error(let message) = viewModel.state {
      #expect(message.contains("Test failure") || !message.isEmpty)
    } else {
      Issue.record("Expected error state")
    }

    tearDownFeedTestDependencies()
  }

  @Test("deletePost removes post from list on success")
  @MainActor
  func deletePostSuccess() async {
    let mockUseCase = MockFeedPostUseCase()
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedViewModel()

    // Simulate loaded state with posts
    viewModel.posts = [
      FeedTestFixtures.makePost(id: "1"),
      FeedTestFixtures.makePost(id: "2"),
      FeedTestFixtures.makePost(id: "3")
    ]

    await viewModel.deletePost(postID: "2")

    #expect(viewModel.posts.count == 2)
    #expect(viewModel.posts.contains { $0.id == "2" } == false)
    #expect(mockUseCase.deletePostCallCount == 1)
    #expect(mockUseCase.lastDeletePostID == "2")

    tearDownFeedTestDependencies()
  }

  @Test("deletePost shows alert on error")
  @MainActor
  func deletePostError() async {
    let mockUseCase = MockFeedPostUseCase()
    mockUseCase.deletePostResult = .failure(TestError.testFailure)
    setupFeedTestDependencies(feedPostUseCase: mockUseCase)

    let viewModel = FeedViewModel()

    viewModel.posts = [
      FeedTestFixtures.makePost(id: "1")
    ]

    await viewModel.deletePost(postID: "1")

    // Post should still be in list since delete failed
    #expect(viewModel.posts.count == 1)
    #expect(viewModel.isAlertPresented == true)
    #expect(viewModel.alertState != nil)

    tearDownFeedTestDependencies()
  }

  @Test("signOut delegates to authUseCase")
  @MainActor
  func signOutDelegatesToUseCase() async throws {
    let mockAuthUseCase = MockAuthUseCase()
    setupFeedTestDependencies(authUseCase: mockAuthUseCase)

    let viewModel = FeedViewModel()

    try await viewModel.signOut()

    #expect(mockAuthUseCase.signOutCallCount == 1)

    tearDownFeedTestDependencies()
  }
}
