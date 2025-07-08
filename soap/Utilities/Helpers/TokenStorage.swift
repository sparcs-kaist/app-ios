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
  private static let accessTokenKey = "accessToken"
  private static let refreshTokenKey = "refreshToken"

  func save(accessToken: String, refreshToken: String) {
    keychain.set(accessToken, forKey: TokenStorage.accessTokenKey)
    keychain.set(refreshToken, forKey: TokenStorage.refreshTokenKey)
    logger.info("Tokens saved to Keychain.")
  }

  func getAccessToken() -> String? {
    return keychain.get(TokenStorage.accessTokenKey)
  }

  func getRefreshToken() -> String? {
    return keychain.get(TokenStorage.refreshTokenKey)
  }

  func clearTokens() {
    keychain.delete(TokenStorage.accessTokenKey)
    keychain.delete(TokenStorage.refreshTokenKey)
    logger.info("Tokens cleared from Keychain.")
  }
}
