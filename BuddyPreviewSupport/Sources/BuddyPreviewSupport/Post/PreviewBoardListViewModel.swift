//
//  PreviewBoardListViewModel.swift
//  BuddyPreviewSupport
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import BuddyDomain
import Observation

@MainActor
@Observable
public final class PreviewBoardListViewModel: BoardListViewModelProtocol {
  public var state: BoardListViewState
  public var boardsWithNewPosts: Set<Int> = []
  public var sections: [BoardListSection] = BoardListSection.defaults

  public init(state: BoardListViewState) {
    self.state = state
  }

  public func fetchBoards() async { }

  public func posts(for section: BoardListSection) -> [AraPost]? {
    switch section {
    case .trending: Array(AraPost.mockList.prefix(3))
    case .latest: Array(AraPost.mockList.suffix(3))
    case .board: Array(AraPost.mockList.prefix(6))
    }
  }

  public func reloadSections() { }

  public static func loadedState() -> BoardListViewState {
    let boards = AraBoard.mockList
    let groups = Array(Set(boards.map(\.group))).sorted { $0.id < $1.id }
    return .loaded(boards: boards, groups: groups)
  }
}
