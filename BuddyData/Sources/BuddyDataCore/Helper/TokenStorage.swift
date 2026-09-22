//
//  TokenStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine
import BuddyDomain

/// TokenStorage stores non-Sendable types (Keychain, CurrentValueSubject).
/// We assert thread-safety at the call sites and confine usage appropriately.
/// Use @unchecked Sendable to satisfy protocol conformance under Swift's strict concurrency checking.
public final class TokenStorage: @unchecked Sendable, TokenStorageProtocol {
  private let keychain = Keychain()
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
    for key in [Self.accessTokenKey, Self.refreshTokenKey, Self.tokenExpirationKey] {
      keychain.setAccessibility(.accessibleAfterFirstUnlock, forKey: key)
    }
  }

  public func save(accessToken: String, refreshToken: String?) throws {
    // Persist the rotated refresh token first so a later write failure can still
    // recover the session. Do not publish success until every write succeeds.
    if let refreshToken {
      try keychain.setData(Data(refreshToken.utf8), forKey: Self.refreshTokenKey, withAccess: .accessibleAfterFirstUnlock)
    }
    try keychain.setData(Data(accessToken.utf8), forKey: Self.accessTokenKey, withAccess: .accessibleAfterFirstUnlock)

    if let expirationDate = extractExpirationDate(from: accessToken) {
      let expirationTimeInterval = expirationDate.timeIntervalSince1970
      try keychain.setData(Data(String(expirationTimeInterval).utf8), forKey: Self.tokenExpirationKey,
        withAccess: .accessibleAfterFirstUnlock)
      tokenStateSubject.send(TokenState(accessToken: accessToken, expiresAt: expirationDate))
    }
  }

  public func getAccessToken() -> String? {
    return keychain.get(TokenStorage.accessTokenKey)
  }

  public func getRefreshToken() -> String? {
    try? readRefreshToken()
  }

  public func readRefreshToken() throws -> String? {
    guard let data = try keychain.readData(Self.refreshTokenKey) else { return nil }
    guard let token = String(data: data, encoding: .utf8) else {
      throw CocoaError(.fileReadCorruptFile)
    }
    return token
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
