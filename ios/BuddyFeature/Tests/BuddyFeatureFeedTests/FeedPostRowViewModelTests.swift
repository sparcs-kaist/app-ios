//
//  FeedPostRowViewModelTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import SwiftUI
@testable import BuddyFeatureFeed
@testable import BuddyDomain
import BuddyTestSupport

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
