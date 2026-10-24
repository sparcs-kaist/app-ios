//
//  BoardListViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import Observation

@MainActor
public protocol BoardListViewModelProtocol: Observable {
  var state: BoardListViewState { get }
  /// Boards with posts newer than the newest one seen in their list.
  var boardsWithNewPosts: Set<Int> { get }
  /// The week's most viewed posts across boards, top first; `nil` while loading, empty if
  /// they couldn't be.
  var trendingPosts: [AraPost]? { get }
  /// The newest posts across boards, Portal Notice aside; `nil` while loading.
  var latestPosts: [AraPost]? { get }
  /// The newest Market listings, for its shelf; `nil` while loading.
  var marketPosts: [AraPost]? { get }

  func fetchBoards() async
}
