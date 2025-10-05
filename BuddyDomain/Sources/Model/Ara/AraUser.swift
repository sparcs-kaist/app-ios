//
//  AraUser.swift
//  soap
//
//  Created by 하정우 on 8/19/25.
//

import Foundation

public struct AraUser: Identifiable, Sendable {
  public let id: Int
  public let nickname: String
  public let nicknameUpdatedAt: Date?
  public let allowNSFW: Bool
  public let allowPolitical: Bool

  public init(
    id: Int,
    nickname: String,
    nicknameUpdatedAt: Date?,
    allowNSFW: Bool,
    allowPolitical: Bool
  ) {
    self.id = id
    self.nickname = nickname
    self.nicknameUpdatedAt = nicknameUpdatedAt
    self.allowNSFW = allowNSFW
    self.allowPolitical = allowPolitical
  }
}
