//
//  PostListViewModelTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import Testing
import BuddyTestSupport
import BuddyFeatureShared
@testable import BuddyFeaturePost
@testable import BuddyDomain

extension PostFeatureTests {
  @Suite("Board post list")
  @MainActor
  struct PostListViewModelTests {
    private let meal = AraBoardTopic(id: 31, slug: "meal", name: LocalizedString(["en": "Meal", "ko": "식사"]))

    private func useCase(posts: [AraPost]) -> MockAraBoardUseCase {
      let useCase = MockAraBoardUseCase()
      useCase.fetchPostsHandler = { _ in AraFixtures.page(posts) }
      return useCase
    }

    @Test func filtersByTheChosenTopic() async throws {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase(posts: [AraFixtures.post(id: 1)])
      setupPostTestDependencies(araBoardUseCase: useCase)
      let viewModel = PostListViewModel(board: AraFixtures.board(topics: [meal]))
      await viewModel.fetchInitialPosts()

      viewModel.selectedTopic = meal
      // Choosing a topic clears the list and reloads it.
      #expect(viewModel.posts.isEmpty)
      #expect(viewModel.state == .loading)
      try await waitUntil { viewModel.state != .loading }

      #expect(useCase.fetchPostsCalls.first?.type == .board(boardID: 2, topicID: nil))
      #expect(useCase.fetchPostsCalls.last?.type == .board(boardID: 2, topicID: 31))
    }

    @Test func choosingTheSameTopicDoesNotReload() async {
      defer { tearDownPostTestDependencies() }

      let useCase = useCase(posts: [])
      setupPostTestDependencies(araBoardUseCase: useCase)
      let viewModel = PostListViewModel(board: AraFixtures.board(topics: [meal]))
      viewModel.selectedTopic = nil

      #expect(useCase.fetchPostsCalls.isEmpty)
    }

    @Test func seeingTheWholeBoardMarksItsNewestPostSeen() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      setupPostTestDependencies(araBoardUseCase: useCase(posts: [AraFixtures.post(id: 40), AraFixtures.post(id: 42)]))
      let viewModel = PostListViewModel(board: AraFixtures.board())
      await viewModel.fetchInitialPosts()

      #expect(BoardSeenPosts.newestSeen(inBoard: 2) == 42)
    }

    @Test func aTopicOrSearchDoesNotCountAsSeeingTheBoard() async throws {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      setupPostTestDependencies(araBoardUseCase: useCase(posts: [AraFixtures.post(id: 42)]))
      let viewModel = PostListViewModel(board: AraFixtures.board(topics: [meal]))
      viewModel.selectedTopic = meal
      try await waitUntil { viewModel.state != .loading }

      #expect(BoardSeenPosts.newestSeen(inBoard: 2) == nil)
    }

    /// Polls the main actor until `condition` holds, for work the view model starts on its own.
    private func waitUntil(_ condition: () -> Bool) async throws {
      for _ in 0..<100 where !condition() {
        try await Task.sleep(for: .milliseconds(10))
      }
      #expect(condition())
    }
  }
}
