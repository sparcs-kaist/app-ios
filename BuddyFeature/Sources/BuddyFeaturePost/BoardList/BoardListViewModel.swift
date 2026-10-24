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

  public init() { }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  public func fetchBoards() async {
    guard let araBoardUseCase else { return }

    do {
      let boards = try await araBoardUseCase.fetchBoards()

      let sortedBoards = boards.sorted { $0.id < $1.id }
      let uniqueGroups = Array(Set(sortedBoards.map(\.group))).sorted { $0.id < $1.id }

      self.boards = sortedBoards
      self.groups = uniqueGroups
      state = .loaded(boards: sortedBoards, groups: uniqueGroups)
      analyticsService?.logEvent(BoardListViewEvent.boardsLoaded)
      await checkForNewPosts(in: sortedBoards, using: araBoardUseCase)

    } catch {
      logger.error("Failed to load boards: \(error.localizedDescription, privacy: .public)")
      state = .error(message: String(localized: "Failed to load boards.", bundle: .module))
    }
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
