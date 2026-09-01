//
//  FeedPostUseCaseTests.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import Foundation
@testable import BuddyDataCore
@testable import BuddyDomain
import BuddyTestSupport

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
