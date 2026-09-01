//
//  BoardListViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import BuddyDomain
import Foundation

enum BoardListViewEvent: Event {
  case boardsLoaded
  case boardSelected(boardName: String)

  var source: String { "BoardListView" }

  var name: String {
    switch self {
    case .boardsLoaded:
      "boards_loaded"
    case .boardSelected:
      "board_selected"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .boardSelected(let boardName):
      ["source": source, "boardName": boardName]
    default:
      ["source": source]
    }
  }
}
