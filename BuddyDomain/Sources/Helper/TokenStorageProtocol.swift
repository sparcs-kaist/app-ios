//
//  TokenStorageProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation
import Combine

public protocol TokenStorageProtocol: Sendable {
  var tokenStatePublisher: AnyPublisher<TokenState?, Never> { get }
  var currentTokenState: TokenState? { get }

  func save(accessToken: String, refreshToken: String?)
  func getAccessToken() -> String?
  func getRefreshToken() -> String?
  func isTokenExpired() -> Bool
  func getTokenExpirationDate() -> Date?
  func clearTokens()
}
