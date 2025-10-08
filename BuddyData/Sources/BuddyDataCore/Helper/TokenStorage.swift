//
//  TokenStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine
import KeychainSwift
import BuddyDomain

public final class TokenStorage: TokenStorageProtocol {
  private let keychain = KeychainSwift()
  private static let accessTokenKey = "accessToken"
  private static let refreshTokenKey = "refreshToken"
  private static let tokenExpirationKey = "tokenExpiration"

  private let tokenStateSubject = CurrentValueSubject<TokenState?, Never>(nil)
  public var tokenStatePublisher: AnyPublisher<TokenState?, Never> {
    tokenStateSubject.eraseToAnyPublisher()
  }

  public var currentTokenState: TokenState? {
    guard let at = getAccessToken(),
          let exp = getTokenExpirationDate()
    else { return nil }

    return TokenState(accessToken: at, expiresAt: exp)
  }

  public init() {
    keychain.accessGroup = "N5V8W52U3U.org.sparcs.soap"
  }

  public func save(accessToken: String, refreshToken: String?) {
    keychain.set(accessToken, forKey: TokenStorage.accessTokenKey, withAccess: .none)
    if let refreshToken {
      keychain.set(refreshToken, forKey: TokenStorage.refreshTokenKey, withAccess: .none)
    }

    if let expirationDate = extractExpirationDate(from: accessToken) {
      let expirationTimeInterval = expirationDate.timeIntervalSince1970
      keychain.set(String(expirationTimeInterval), forKey: TokenStorage.tokenExpirationKey)
      tokenStateSubject.send(TokenState(accessToken: accessToken, expiresAt: expirationDate))
    }
  }

  public func getAccessToken() -> String? {
    return keychain.get(TokenStorage.accessTokenKey)
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
    keychain.delete(TokenStorage.accessTokenKey)
    keychain.delete(TokenStorage.refreshTokenKey)
    keychain.delete(TokenStorage.tokenExpirationKey)
    tokenStateSubject.send(nil)
  }
  
  // MARK: - Private Methods
  
  private func extractExpirationDate(from jwtToken: String) -> Date? {
    let components = jwtToken.components(separatedBy: ".")
    guard components.count == 3 else { return nil }
    
    let payload = components[1]
    // JWT uses base64url encoding. Convert to standard Base64 before decoding.
    let base64Payload = payload
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let paddedPayload: String = {
      let remainder = base64Payload.count % 4
      if remainder == 0 { return base64Payload }
      return base64Payload.padding(toLength: base64Payload.count + (4 - remainder), withPad: "=", startingAt: 0)
    }()
    guard let data = Data(base64Encoded: paddedPayload),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let exp = json["exp"] as? TimeInterval else {
      return nil
    }
    
    return Date(timeIntervalSince1970: exp)
  }
}
