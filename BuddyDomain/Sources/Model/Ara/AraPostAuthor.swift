//
//  AraPostAuthor.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPostAuthor: Identifiable, Hashable, Sendable {
  public let id: String
  public let username: String
  public let profile: AraPostAuthorProfile
  public let isBlocked: Bool?

  /// The account to block, for authors named by their nickname. Ara sends `is_blocked` only for
  /// them; anonymous authors get a per-post hash and real-name authors a disguised number, and
  /// blocking either would block the wrong account or none.
  public var blockableUserID: Int? {
    isBlocked == nil ? nil : Int(id)
  }

  public init(id: String, username: String, profile: AraPostAuthorProfile, isBlocked: Bool?) {
    self.id = id
    self.username = username
    self.profile = profile
    self.isBlocked = isBlocked
  }
}
