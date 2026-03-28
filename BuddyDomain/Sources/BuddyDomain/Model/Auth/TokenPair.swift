//
//  TokenPair.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

public struct TokenPair: Codable, Sendable {
  public let accessToken: String
  public let refreshToken: String
  public let expiry: Date

  public init(accessToken: String, refreshToken: String, expiry: Date) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.expiry = expiry
  }
}
