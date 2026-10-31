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
    /// Sections saved in a throwaway suite, so neither the tests nor the simulator's own choices
    /// affect the other.
    private let sectionStore = BoardListSectionStore(defaults: UserDefaults(suiteName: "BoardListViewModelTests.\(UUID())")!)

    /// A use case serving `boards`, and each board's newest post from `newest`.
    private func useCase(
      newest: [AraPost] = [],
      trending: [AraPost] = [],
      latest: [AraPost] = [],
      market: [AraPost] = [],
      talkPosts: [AraPost] = []
    ) -> MockAraBoardUseCase {
      let useCase = MockAraBoardUseCase()
      useCase.fetchBoardsResult = .success(boards)
      useCase.fetchPostsHandler = { call in
        switch call.type {
        case .trending: AraFixtures.page(trending)
        case .latest: AraFixtures.page(latest + newest)
        case .boardSlug("market"): AraFixtures.page(market)
        case .boardSlug("talk"): AraFixtures.page(talkPosts)
        default: AraFixtures.page([])
        }
      }
      return useCase
    }

    private func load(_ useCase: MockAraBoardUseCase) async -> BoardListViewModel {
      setupPostTestDependencies(araBoardUseCase: useCase)
      let viewModel = BoardListViewModel(sectionStore: sectionStore)
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
      #expect(viewModel.posts(for: .trending)?.map(\.id) == [1])
      #expect(viewModel.posts(for: .latest)?.map(\.id) == [2])
      #expect(viewModel.posts(for: .board(slug: "market"))?.map(\.id) == [3])
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
      let viewModel = BoardListViewModel(sectionStore: sectionStore)
      // `nil` is what shows the placeholder.
      #expect(viewModel.posts(for: .trending) == nil)
      #expect(viewModel.posts(for: .latest) == nil)
      #expect(viewModel.posts(for: .board(slug: "market")) == nil)

      await viewModel.fetchBoards()
      #expect(viewModel.posts(for: .trending) == [])
      #expect(viewModel.posts(for: .latest) == [])
      #expect(viewModel.posts(for: .board(slug: "market")) == [])
    }

    @Test func aFailedRefreshKeepsWhatWasShown() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase(trending: [AraFixtures.post(id: 1)])
      let viewModel = await load(useCase)
      useCase.fetchPostsHandler = { _ in throw TestError.testFailure }
      await viewModel.fetchBoards()

      #expect(viewModel.posts(for: .trending)?.map(\.id) == [1])
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

    // MARK: - Choosing sections

    @Test func startsWithTheDefaultSections() {
      defer { tearDownPostTestDependencies() }
      setupPostTestDependencies()
      #expect(BoardListViewModel(sectionStore: sectionStore).sections == [.trending, .latest, .board(slug: "market")])
    }

    @Test func loadsOnlyTheChosenSectionsInTheirOrder() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      sectionStore.save([.board(slug: "talk"), .trending])
      let useCase = useCase(trending: [AraFixtures.post(id: 1)], talkPosts: [AraFixtures.post(id: 9)])
      let viewModel = await load(useCase)

      #expect(viewModel.sections == [.board(slug: "talk"), .trending])
      #expect(viewModel.posts(for: .board(slug: "talk"))?.map(\.id) == [9])
      #expect(viewModel.posts(for: .trending)?.map(\.id) == [1])
      let calls = useCase.fetchPostsCalls
      #expect(!calls.contains { $0.type == .boardSlug("market") })
      // The new-post check also asks for the latest posts, but not as the section does.
      #expect(!calls.contains {
        if case .latest = $0.type { $0.pageSize == BoardListViewModel.highlightCount } else { false }
      })
    }

    @Test func followsSectionsSavedInSettings() async throws {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let viewModel = await load(useCase(talkPosts: [AraFixtures.post(id: 9)]))
      // As Settings does, through its own model.
      let settings = BoardSectionsSettingsModel(store: sectionStore)
      settings.sections = [.board(slug: "talk"), .latest]
      viewModel.reloadSections()

      #expect(viewModel.sections == [.board(slug: "talk"), .latest])
      for _ in 0..<100 where viewModel.posts(for: .board(slug: "talk")) == nil {
        try await Task.sleep(for: .milliseconds(10))
      }
      #expect(viewModel.posts(for: .board(slug: "talk"))?.map(\.id) == [9])
    }

    // MARK: - New post dots

    @Test func marksBoardsNeverOpenedWhoseNewestIsUnread() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let viewModel = await load(useCase(newest: [
        AraFixtures.post(id: 200, board: AraFixtures.board(id: 5), readStatus: .read),
        AraFixtures.post(id: 100, board: AraFixtures.board(id: 2), readStatus: .unread),
      ]))

      #expect(viewModel.boardsWithNewPosts == [2])
    }

    @Test func marksOnlyPostsNewerThanTheNewestSeen() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      BoardSeenPosts.markSeen(100, inBoard: 2)
      BoardSeenPosts.markSeen(199, inBoard: 5)
      let viewModel = await load(useCase(newest: [
        AraFixtures.post(id: 200, board: AraFixtures.board(id: 5), readStatus: .unread),
        // Seen in the list, though never opened.
        AraFixtures.post(id: 100, board: AraFixtures.board(id: 2), readStatus: .unread),
      ]))

      #expect(viewModel.boardsWithNewPosts == [5])
    }

    @Test func judgesABoardByItsNewestPost() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      BoardSeenPosts.markSeen(150, inBoard: 2)
      let viewModel = await load(useCase(newest: [
        AraFixtures.post(id: 200, board: AraFixtures.board(id: 2), readStatus: .unread),
        AraFixtures.post(id: 100, board: AraFixtures.board(id: 2), readStatus: .unread),
      ]))

      #expect(viewModel.boardsWithNewPosts == [2])
    }

    @Test func checksForNewPostsInOneRequest() async {
      BoardSeenPosts.reset()
      defer { tearDownPostTestDependencies(); BoardSeenPosts.reset() }

      let useCase = useCase()
      _ = await load(useCase)

      #expect(!useCase.fetchPostsCalls.contains { if case .board = $0.type { true } else { false } })
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
