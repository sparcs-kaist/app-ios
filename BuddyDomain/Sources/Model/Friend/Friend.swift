//
//  Friend.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

public struct Friend: Identifiable, Sendable, Equatable, Hashable {
  public let id: Int
  public let name: String
  public let isFavorite: Bool
  /// Whether the friend has a lecture or activity in progress right now, or `nil`
  /// when no semester is running and the server can't tell.
  public let hasScheduleNow: Bool?

  public init(
    id: Int,
    name: String,
    isFavorite: Bool,
    hasScheduleNow: Bool?
  ) {
    self.id = id
    self.name = name
    self.isFavorite = isFavorite
    self.hasScheduleNow = hasScheduleNow
  }
}
