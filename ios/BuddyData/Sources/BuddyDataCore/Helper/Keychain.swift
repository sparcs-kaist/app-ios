//
//  Keychain.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 10/06/2026.
//

import Foundation
import Security

/// A minimal Keychain wrapper for the small subset of functionality the app needs.
///
/// Implemented directly on top of the Security framework so we don't depend on an
/// external keychain package. Items are stored using the same item class
/// (`kSecClassGenericPassword`) and account attribute (`kSecAttrAccount`) as before,
/// so values previously written by the old library remain readable.
public final class Keychain {
  /// Access group used to share keychain items between the app and its extensions.
  public var accessGroup: String?

  public init() {}

  @discardableResult
  public func set(_ value: String, forKey key: String, withAccess access: KeychainAccessOptions? = nil) -> Bool {
    guard let data = value.data(using: .utf8) else { return false }
    return set(data, forKey: key, withAccess: access)
  }

  @discardableResult
  public func set(_ value: Data, forKey key: String, withAccess access: KeychainAccessOptions? = nil) -> Bool {
    // Overwrite any existing value for this key.
    delete(key)

    let accessible = (access ?? .accessibleWhenUnlocked).value

    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: value,
      kSecAttrAccessible as String: accessible,
    ]
    query = addingAccessGroup(to: query)

    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }

  public func get(_ key: String) -> String? {
    guard let data = getData(key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func getData(_ key: String) -> Data? {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: kCFBooleanTrue as Any,
    ]
    query = addingAccessGroup(to: query)

    var result: AnyObject?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
    return result as? Data
  }

  @discardableResult
  public func delete(_ key: String) -> Bool {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]
    query = addingAccessGroup(to: query)

    return SecItemDelete(query as CFDictionary) == errSecSuccess
  }

  private func addingAccessGroup(to query: [String: Any]) -> [String: Any] {
    guard let accessGroup else { return query }
    var query = query
    query[kSecAttrAccessGroup as String] = accessGroup
    return query
  }
}

/// Keychain item accessibility options, mirroring the subset the app relies on.
public enum KeychainAccessOptions {
  /// The data is accessible only while the device is unlocked by the user.
  case accessibleWhenUnlocked
  /// The data is accessible after the first unlock following a restart.
  case accessibleAfterFirstUnlock

  var value: CFString {
    switch self {
    case .accessibleWhenUnlocked: return kSecAttrAccessibleWhenUnlocked
    case .accessibleAfterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
    }
  }
}
