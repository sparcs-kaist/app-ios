//
//  FriendList.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

public struct FriendList: Sendable, Equatable {
  /// When the server last recomputed the friends' current-schedule status.
  public let checkedAt: Date?
  public let friends: [Friend]

  public init(checkedAt: Date?, friends: [Friend]) {
    self.checkedAt = checkedAt
    self.friends = friends
  }
}
