//
//  FriendListResponseDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation
import BuddyDomain

public struct FriendListResponseDTO: Decodable {
  public let checkedAt: String?
  public let friends: [FriendDTO]
}

public extension FriendListResponseDTO {
  func toModel() -> FriendList {
    FriendList(
      checkedAt: checkedAt.flatMap(Self.parseDate),
      friends: friends.map { $0.toModel() }
    )
  }

  // `checkedAt` comes back as ISO8601 with fractional seconds (e.g.
  // "2026-09-28T04:31:18.000Z"), so allow the fractional-seconds option.
  private static func parseDate(_ string: String) -> Date? {
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFraction.date(from: string) { return date }

    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return plain.date(from: string)
  }
}
