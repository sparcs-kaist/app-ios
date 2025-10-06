//
//  TokenState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation

public struct TokenState: Equatable, Sendable {
  public let accessToken: String
  public let expiresAt: Date

  public init(accessToken: String, expiresAt: Date) {
    self.accessToken = accessToken
    self.expiresAt = expiresAt
  }
}
