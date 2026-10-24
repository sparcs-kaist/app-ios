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

  func fetchBoards() async
}
