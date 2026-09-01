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

  func fetchBoards() async
}
