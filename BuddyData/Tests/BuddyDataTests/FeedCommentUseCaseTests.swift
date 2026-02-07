//
//  FeedCommentUseCaseTests.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import Foundation
@testable import BuddyDataCore
@testable import BuddyDomain
import BuddyTestSupport

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
