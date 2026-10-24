//
//  BoardListViewModelTests.swift
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
  @Suite("Boards list")
  @MainActor
  struct BoardListViewModelTests {
    private let talk = AraFixtures.board(id: 2, slug: "talk")
    private let club = AraFixtures.board(id: 5, slug: "club")

    private var boards: [AraBoard] { [AraFixtures.portalNotice, talk, club, AraFixtures.market] }

    /// A use case serving `boards`, and each board's newest post from `newest`.
    private func useCase(
      newest: [Int: AraPost] = [:],
      trending: [AraPost] = [],
      latest: [AraPost] = [],
      market: [AraPost] = []
    ) -> MockAraBoardUseCase {
      let useCase = MockAraBoardUseCase()
      useCase.fetchBoardsResult = .success(boards)
      useCase.fetchPostsHandler = { call in
        switch call.type {
        case .trending: AraFixtures.page(trending)
        case .latest: AraFixtures.page(latest)
        case .boardSlug("market"): AraFixtures.page(market)
        case .board(let boardID, nil): AraFixtures.page(newest[boardID].map { [$0] } ?? [])
        default: AraFixtures.page([])
        }
      }
      return useCase
    }

    private func load(_ useCase: MockAraBoardUseCase) async -> BoardListViewModel {
      setupPostTestDependencies(araBoardUseCase: useCase)
      let viewModel = BoardListViewModel()
      await viewModel.fetchBoards()
      return viewModel
    }

    // MARK: - Sections

    @Test func loadsEverySection() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase(
        trending: [AraFixtures.post(id: 1)],
        latest: [AraFixtures.post(id: 2)],
        market: [AraFixtures.post(id: 3, board: AraFixtures.market)]
      )
      let viewModel = await load(useCase)

      #expect(viewModel.state == .loaded(boards: boards.sorted { $0.id < $1.id }, groups: [AraFixtures.group]))
      #expect(viewModel.trendingPosts?.map(\.id) == [1])
      #expect(viewModel.latestPosts?.map(\.id) == [2])
      #expect(viewModel.marketPosts?.map(\.id) == [3])
    }

    @Test func asksForMarketBySlugAndLatestWithoutPortalNotice() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase()
      _ = await load(useCase)
      let calls = useCase.fetchPostsCalls

      #expect(calls.contains { $0.type == .trending && $0.pageSize == BoardListViewModel.highlightCount })
      #expect(calls.contains { $0.type == .boardSlug("market") && $0.pageSize == BoardListViewModel.marketShelfCount })
      #expect(calls.contains { $0.type == .latest(boardIDs: [2, 5, 7]) })
    }

    @Test func sectionsStartUnloadedAndAreEmptyIfTheyFail() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase()
      useCase.fetchPostsHandler = { _ in throw TestError.testFailure }
      setupPostTestDependencies(araBoardUseCase: useCase)
      let viewModel = BoardListViewModel()
      // `nil` is what shows the placeholder.
      #expect(viewModel.trendingPosts == nil)
      #expect(viewModel.latestPosts == nil)
      #expect(viewModel.marketPosts == nil)

      await viewModel.fetchBoards()
      #expect(viewModel.trendingPosts == [])
      #expect(viewModel.latestPosts == [])
      #expect(viewModel.marketPosts == [])
    }

    @Test func aFailedRefreshKeepsWhatWasShown() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase(trending: [AraFixtures.post(id: 1)])
      let viewModel = await load(useCase)
      useCase.fetchPostsHandler = { _ in throw TestError.testFailure }
      await viewModel.fetchBoards()

      #expect(viewModel.trendingPosts?.map(\.id) == [1])
    }

    @Test func showsAnErrorWhenTheBoardsFail() async {
      defer { tearDownPostTestDependencies() }

      let useCase = useCase()
      useCase.fetchBoardsResult = .failure(TestError.testFailure)
      let viewModel = await load(useCase)

      guard case .error = viewModel.state else {
        Issue.record("Expected an error, got \(viewModel.state)")
        return
      }
    }

    @Test func latestLeavesOutPortalNoticeAndUnreadableBoards() {
      let hidden = AraFixtures.board(id: 9, slug: "hidden", readable: false)
      let ids = BoardListViewModel.latestBoardIDs(in: [AraFixtures.portalNotice, talk, hidden, AraFixtures.market])
      #expect(ids == [2, 7])
    }

    // MARK: - New post dots

    @Test func marksBoardsNeverOpenedWhoseNewestIsUnread() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let viewModel = await load(useCase(newest: [
        2: AraFixtures.post(id: 100, readStatus: .unread),
        5: AraFixtures.post(id: 200, readStatus: .read),
      ]))

      #expect(viewModel.boardsWithNewPosts == [2])
    }

    @Test func marksOnlyPostsNewerThanTheNewestSeen() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      BoardSeenPosts.markSeen(100, inBoard: 2)
      BoardSeenPosts.markSeen(199, inBoard: 5)
      let viewModel = await load(useCase(newest: [
        // Seen in the list, though never opened.
        2: AraFixtures.post(id: 100, readStatus: .unread),
        5: AraFixtures.post(id: 200, readStatus: .unread),
      ]))

      #expect(viewModel.boardsWithNewPosts == [5])
    }

    @Test func seenPostsOnlyMoveForward() {
      BoardSeenPosts.reset()
      defer { BoardSeenPosts.reset() }

      BoardSeenPosts.markSeen(200, inBoard: 2)
      BoardSeenPosts.markSeen(150, inBoard: 2)
      #expect(BoardSeenPosts.newestSeen(inBoard: 2) == 200)
      #expect(BoardSeenPosts.newestSeen(inBoard: 3) == nil)
    }
  }
}
