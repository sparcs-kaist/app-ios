//
//  KeychainTokenStore.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation
import BuddyDomain

public struct KeychainTokenStore: TokenStoring {
  private let service = "buddy.auth.tokenpair"
  private let account = "default"
  private let accessGroup = "N5V8W52U3U.org.sparcs.soap"

  public init() { }

  public func save(_ tokenPair: TokenPair) throws {
    let data = try JSONEncoder().encode(tokenPair)

    try deleteIfExists()

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }

  public func load() throws -> TokenPair? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }

    guard let data = item as? Data else {
      throw KeychainError.invalidData
    }

    return try JSONDecoder().decode(TokenPair.self, from: data)
  }

  public func clear() throws {
    try deleteIfExists()
  }

  private func deleteIfExists() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup
    ]

    let status = SecItemDelete(query as CFDictionary)

    if status != errSecSuccess && status != errSecItemNotFound {
      throw KeychainError.unexpectedStatus(status)
    }
  }
}

enum KeychainError: Error {
  case unexpectedStatus(OSStatus)
  case invalidData
}
