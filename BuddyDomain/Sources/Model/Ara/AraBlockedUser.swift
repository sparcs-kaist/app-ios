//
//  AraBlockedUser.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/10/2026.
//

import Foundation

/// Someone the signed-in user has blocked on Ara.
public struct AraBlockedUser: Identifiable, Hashable, Sendable {
  /// Their account, which unblocking takes.
  public let id: Int
  public let nickname: String
  public let profilePictureURL: URL?

  public init(id: Int, nickname: String, profilePictureURL: URL?) {
    self.id = id
    self.nickname = nickname
    self.profilePictureURL = profilePictureURL
  }
}
