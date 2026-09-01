//
//  FeedCommentRowViewModelTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import SwiftUI
@testable import BuddyFeatureFeed
@testable import BuddyDomain
import BuddyTestSupport

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
