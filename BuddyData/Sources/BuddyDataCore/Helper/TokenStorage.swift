//
//  TokenStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import KeychainSwift
import BuddyDomain

public class TokenStorage: TokenStorageProtocol {
  private let keychain = KeychainSwift()
  private static let acessTokenKey = "accessToken"
  private static let refreshTokenKey = "refreshToken"
  private static let tokenExpirationKey = "tokenExpiration"

  public init() {
    
  }

  public func save(accessToken: String, refreshToken: String) {
    keychain.set(accessToken, forKey: TokenStorage.acessTokenKey)
    keychain.set(refreshToken, forKey: TokenStorage.refreshTokenKey)

    if let expirationDate = extractExpirationDate(from: accessToken) {
      let expirationTimeInterval = expirationDate.timeIntervalSince1970
      keychain.set(String(expirationTimeInterval), forKey: TokenStorage.tokenExpirationKey)
    }
  }

  public func getAccessToken() -> String? {
    return keychain.get(TokenStorage.acessTokenKey)
  }

  public func getRefreshToken() -> String? {
    return keychain.get(TokenStorage.refreshTokenKey)
  }
  
  public func isTokenExpired() -> Bool {
    guard let expirationString = keychain.get(TokenStorage.tokenExpirationKey),
          let expirationTimeInterval = Double(expirationString) else {
      return true
    }
    
    let expirationDate = Date(timeIntervalSince1970: expirationTimeInterval)
    let currentDate = Date()
    
    // refresh 5 min before it expires
    let bufferTime: TimeInterval = 5 * 60
    return currentDate.addingTimeInterval(bufferTime) >= expirationDate
  }
  
  public func getTokenExpirationDate() -> Date? {
    guard let expirationString = keychain.get(TokenStorage.tokenExpirationKey),
          let expirationTimeInterval = Double(expirationString) else {
      return nil
    }
    return Date(timeIntervalSince1970: expirationTimeInterval)
  }

  public func clearTokens() {
    keychain.delete(TokenStorage.acessTokenKey)
    keychain.delete(TokenStorage.refreshTokenKey)
    keychain.delete(TokenStorage.tokenExpirationKey)
  }
  
  // MARK: - Private Methods
  
  private func extractExpirationDate(from jwtToken: String) -> Date? {
    let components = jwtToken.components(separatedBy: ".")
    guard components.count == 3 else { return nil }
    
    let payload = components[1]
    guard let data = Data(base64Encoded: payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let exp = json["exp"] as? TimeInterval else {
      return nil
    }
    
    return Date(timeIntervalSince1970: exp)
  }
}
