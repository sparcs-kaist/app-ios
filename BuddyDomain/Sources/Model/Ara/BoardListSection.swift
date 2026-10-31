//
//  BoardListSection.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 25/10/2026.
//

import Foundation

/// A section previewing posts above the list of boards, in the order the reader chose.
public enum BoardListSection: Hashable, Codable, Sendable, Identifiable {
  /// The week's most viewed posts across boards.
  case trending
  /// The newest posts across boards.
  case latest
  /// The newest posts of one board, by its slug, which stays the same across launches.
  case board(slug: String)

  public var id: String {
    switch self {
    case .trending: "trending"
    case .latest: "latest"
    case .board(let slug): "board:\(slug)"
    }
  }

  /// What the Boards list shows until the reader changes it.
  public static let defaults: [BoardListSection] = [.trending, .latest, .board(slug: AraBoard.marketSlug)]
}
