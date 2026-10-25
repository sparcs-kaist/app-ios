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
  /// The sections above the boards, in the reader's order.
  var sections: [BoardListSection] { get }

  /// A section's posts, newest or top first; `nil` while loading, empty if they couldn't be.
  func posts(for section: BoardListSection) -> [AraPost]?
  /// Picks up the sections as last saved in Settings, loading any not loaded yet.
  func reloadSections()
  func fetchBoards() async
}
