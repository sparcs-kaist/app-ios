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

  public init(id: String, username: String, profile: AraPostAuthorProfile, isBlocked: Bool?) {
    self.id = id
    self.username = username
    self.profile = profile
    self.isBlocked = isBlocked
  }
}
