//
//  BoardListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import BuddyFeatureShared
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "BoardListViewModel")

@MainActor
@Observable
public class BoardListViewModel: BoardListViewModelProtocol {
  // MARK: - Properties
  public var state: BoardListViewState = .loading
  var boards: [AraBoard] = []
  var groups: [AraBoardGroup] = []
  public private(set) var boardsWithNewPosts: Set<Int> = []
  public private(set) var trendingPosts: [AraPost]?
  public private(set) var latestPosts: [AraPost]?
  public private(set) var marketPosts: [AraPost]?

  /// How many listings the Market shelf shows before See All.
  static let marketShelfCount = 10

  /// How many posts each highlight section shows, as on Ara's main page.
  static let highlightCount = 3

  public init() { }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  /// Loads the boards and every section at once. Latest waits only for the boards, which it
  /// needs to leave Portal Notice out; a section that fails is hidden on a first load and left
  /// as it was on a refresh.
  public func fetchBoards() async {
    guard let araBoardUseCase else { return }
    await withDiscardingTaskGroup { group in
      group.addTask { await self.loadTrending(using: araBoardUseCase) }
      group.addTask { await self.loadMarket(using: araBoardUseCase) }
      group.addTask { await self.loadBoardsAndLatest(using: araBoardUseCase) }
    }
  }

  private func loadTrending(using useCase: AraBoardUseCaseProtocol) async {
    let page = try? await useCase.fetchPosts(
      type: .trending, page: 1, pageSize: Self.highlightCount, searchKeyword: nil
    )
    trendingPosts = page?.results ?? trendingPosts ?? []
  }

  /// The Market board's newest listings, by slug so they needn't wait for the boards.
  private func loadMarket(using useCase: AraBoardUseCaseProtocol) async {
    let page = try? await useCase.fetchPosts(
      type: .boardSlug(AraBoard.marketSlug), page: 1, pageSize: Self.marketShelfCount, searchKeyword: nil
    )
    marketPosts = page?.results ?? marketPosts ?? []
  }

  private func loadBoardsAndLatest(using useCase: AraBoardUseCaseProtocol) async {
    do {
      let boards = try await useCase.fetchBoards()

      let sortedBoards = boards.sorted { $0.id < $1.id }
      let uniqueGroups = Array(Set(sortedBoards.map(\.group))).sorted { $0.id < $1.id }

      self.boards = sortedBoards
      self.groups = uniqueGroups
      state = .loaded(boards: sortedBoards, groups: uniqueGroups)
      analyticsService?.logEvent(BoardListViewEvent.boardsLoaded)

      async let newPosts: Void = checkForNewPosts(in: sortedBoards, using: useCase)
      let latest = try? await useCase.fetchPosts(
        type: .latest(boardIDs: Self.latestBoardIDs(in: sortedBoards)),
        page: 1, pageSize: Self.highlightCount, searchKeyword: nil
      )
      latestPosts = latest?.results ?? latestPosts ?? []
      await newPosts
    } catch {
      logger.error("Failed to load boards: \(error.localizedDescription, privacy: .public)")
      state = .error(message: String(localized: "Failed to load boards.", bundle: .module))
    }
  }

  static func latestBoardIDs(in boards: [AraBoard]) -> [Int] {
    boards.filter { $0.slug != "portal-notice" && $0.userReadable != false }.map(\.id)
  }

  /// Looks at each board's newest post, all at once, after the list is on screen.
  private func checkForNewPosts(in boards: [AraBoard], using useCase: AraBoardUseCaseProtocol) async {
    let newest = await withTaskGroup(of: (Int, AraPost?).self) { group in
      for board in boards where board.userReadable != false {
        group.addTask {
          let page = try? await useCase.fetchPosts(
            type: .board(boardID: board.id), page: 1, pageSize: 1, searchKeyword: nil
          )
          return (board.id, page?.results.first)
        }
      }
      var newest: [Int: AraPost] = [:]
      for await (boardID, post) in group {
        newest[boardID] = post
      }
      return newest
    }

    var withNewPosts: Set<Int> = []
    for (boardID, post) in newest {
      // A board whose list hasn't been opened here yet counts every post as new. Either way,
      // a post already opened elsewhere (the web, another device) isn't news.
      let seen = BoardSeenPosts.newestSeen(inBoard: boardID) ?? .min
      if post.id > seen && post.readStatus != .read {
        withNewPosts.insert(boardID)
      }
    }
    boardsWithNewPosts = withNewPosts
  }
}
