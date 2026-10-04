//
//  FriendDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation
import BuddyDomain

public struct FriendDTO: Decodable {
  public let id: Int
  public let name: String
  public let isFavorite: Bool
  public let hasScheduleNow: Bool
}

public extension FriendDTO {
  func toModel() -> Friend {
    Friend(
      id: id,
      name: name,
      isFavorite: isFavorite,
      hasScheduleNow: hasScheduleNow
    )
  }
}
