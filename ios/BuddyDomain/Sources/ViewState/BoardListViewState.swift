//
//  BoardListViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation

public enum BoardListViewState: Equatable {
  case loading
  case loaded(boards: [AraBoard], groups: [AraBoardGroup])
  case error(message: String)
}
