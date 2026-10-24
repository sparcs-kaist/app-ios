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
  public var trendingPosts: [AraPost]? = Array(AraPost.mockList.prefix(3))
  public var latestPosts: [AraPost]? = Array(AraPost.mockList.suffix(3))
  public var marketPosts: [AraPost]? = Array(AraPost.mockList.prefix(6))

  public init(state: BoardListViewState) {
    self.state = state
  }

  public func fetchBoards() async { }

  public static func loadedState() -> BoardListViewState {
    let boards = AraBoard.mockList
    let groups = Array(Set(boards.map(\.group))).sorted { $0.id < $1.id }
    return .loaded(boards: boards, groups: groups)
  }
}
