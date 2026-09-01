//
//  FeedViewModelTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Testing
import SwiftUI
@testable import BuddyFeatureFeed
@testable import BuddyDomain
import BuddyTestSupport

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
}
