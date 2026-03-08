//
//  SenderInfo.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import Foundation

public struct SenderInfo: Hashable {
  public let id: String?
  public let name: String?
  public let avatarURL: URL?
  public let isMine: Bool
  public let isWithdrew: Bool

  public init(id: String?, name: String?, avatarURL: URL?, isMine: Bool, isWithdrew: Bool) {
    self.id = id
    self.name = name
    self.avatarURL = avatarURL
    self.isMine = isMine
    self.isWithdrew = isWithdrew
  }
}