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
  public private(set) var sections: [BoardListSection]
  /// Each section's posts once loaded. Kept for a section the reader removes, so adding it back
  /// shows it straight away.
  private var sectionPosts: [BoardListSection: [AraPost]] = [:]

  /// How many listings the Market shelf shows before See All.
  static let marketShelfCount = 10

  /// How many posts each list section shows, as on Ara's main page.
  static let highlightCount = 3

  @ObservationIgnored private let sectionStore: BoardListSectionStore

  public init() {
    self.sectionStore = BoardListSectionStore()
    self.sections = sectionStore.load()
  }

  init(sectionStore: BoardListSectionStore) {
    self.sectionStore = sectionStore
    self.sections = sectionStore.load()
  }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  public func posts(for section: BoardListSection) -> [AraPost]? {
    sectionPosts[section]
  }

  public func reloadSections() {
    let newSections = sectionStore.load()
    guard newSections != sections else { return }
    sections = newSections

    guard let araBoardUseCase else { return }
    for section in newSections where sectionPosts[section] == nil {
      Task { await load(section, using: araBoardUseCase) }
    }
  }

  /// Loads the boards and every section at once. Latest waits only for the boards, which it
  /// needs to leave Portal Notice out; a section that fails is hidden on a first load and left
  /// as it was on a refresh.
  public func fetchBoards() async {
    guard let araBoardUseCase else { return }
    let sections = sections
    await withDiscardingTaskGroup { group in
      for section in sections where section != .latest {
        group.addTask { await self.load(section, using: araBoardUseCase) }
      }
      group.addTask { await self.loadBoardsAndLatest(includingLatest: sections.contains(.latest), using: araBoardUseCase) }
    }
  }

  /// Loads one section's posts. Latest needs the boards first, so it waits for a refresh until
  /// they're in.
  private func load(_ section: BoardListSection, using useCase: AraBoardUseCaseProtocol) async {
    let type: PostListType
    var pageSize = Self.highlightCount
    switch section {
    case .trending:
      type = .trending
    case .latest:
      guard !boards.isEmpty else { return }
      type = .latest(boardIDs: Self.latestBoardIDs(in: boards))
    case .board(let slug):
      // By slug, so it needn't wait for the boards.
      type = .boardSlug(slug)
      if slug == AraBoard.marketSlug { pageSize = Self.marketShelfCount }
    }
    let page = try? await useCase.fetchPosts(type: type, page: 1, pageSize: pageSize, searchKeyword: nil)
    sectionPosts[section] = page?.results ?? sectionPosts[section] ?? []
  }

  private func loadBoardsAndLatest(includingLatest: Bool, using useCase: AraBoardUseCaseProtocol) async {
    do {
      let boards = try await useCase.fetchBoards()

      let sortedBoards = boards.sorted { $0.id < $1.id }
      let uniqueGroups = Array(Set(sortedBoards.map(\.group))).sorted { $0.id < $1.id }

      self.boards = sortedBoards
      self.groups = uniqueGroups
      state = .loaded(boards: sortedBoards, groups: uniqueGroups)
      analyticsService?.logEvent(BoardListViewEvent.boardsLoaded)

      async let newPosts: Void = checkForNewPosts(in: sortedBoards, using: useCase)
      if includingLatest {
        await load(.latest, using: useCase)
      }
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
