//
//  SessionStore.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation
import BuddyDomain

public actor SessionStore {
  private var tokenPair: TokenPair?

  public init() { }

  func update(_ tokenPair: TokenPair) {
    self.tokenPair = tokenPair
  }

  func clear() {
    tokenPair = nil
  }

  func currentTokenPair() -> TokenPair? {
    tokenPair
  }

  func currentAccessToken() -> String? {
    tokenPair?.accessToken
  }

  func currentRefreshToken() -> String? {
    tokenPair?.refreshToken
  }

  func currentExpiry() -> Date? {
    tokenPair?.expiry
  }
}
