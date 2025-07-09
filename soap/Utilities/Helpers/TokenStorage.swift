//
//  TokenStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import KeychainSwift

class TokenStorage: TokenStorageProtocol {
  private let keychain = KeychainSwift()
  private static let refreshTokenKey = "refreshToken"

  private var accessToken: String? = nil

  func save(accessToken: String, refreshToken: String) {
    self.accessToken = accessToken
    keychain.set(refreshToken, forKey: TokenStorage.refreshTokenKey)
    logger.info("Tokens saved to Keychain.")
  }

  func getAccessToken() -> String? {
    // check payload if it's expired
    return accessToken
  }

  func getRefreshToken() -> String? {
    return keychain.get(TokenStorage.refreshTokenKey)
  }

  func clearTokens() {
    self.accessToken = nil
    keychain.delete(TokenStorage.refreshTokenKey)
    logger.info("Tokens cleared from Keychain.")
  }
}
