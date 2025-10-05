//
//  TokenResponse.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public struct TokenResponse: Sendable {
  public let accessToken: String
  public let refreshToken: String

  public init(accessToken: String, refreshToken: String) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
  }
}
