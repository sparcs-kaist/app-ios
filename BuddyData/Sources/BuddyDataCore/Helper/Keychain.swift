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
  private let operations: Operations

  public init() { operations = .live }

  init(operations: Operations) { self.operations = operations }

  /// Injectable Security calls let regression tests exercise locked-device and
  /// failed-write statuses without requiring an entitled, unlocked test host.
  struct Operations {
    var update: ([String: Any], [String: Any]) -> OSStatus
    var add: ([String: Any]) -> OSStatus
    var read: ([String: Any]) -> (OSStatus, Data?)
    var delete: ([String: Any]) -> OSStatus

    static var live: Self {
      Self(
        update: { SecItemUpdate($0 as CFDictionary, $1 as CFDictionary) },
        add: { SecItemAdd($0 as CFDictionary, nil) },
        read: { query in
          var result: AnyObject?
          let status = SecItemCopyMatching(query as CFDictionary, &result)
          return (status, result as? Data)
        },
        delete: { SecItemDelete($0 as CFDictionary) }
      )
    }
  }

  @discardableResult
  public func set(_ value: String, forKey key: String, withAccess access: KeychainAccessOptions? = nil) -> Bool {
    guard let data = value.data(using: .utf8) else { return false }
    return set(data, forKey: key, withAccess: access)
  }

  @discardableResult
  public func set(_ value: Data, forKey key: String, withAccess access: KeychainAccessOptions? = nil) -> Bool {
    do {
      try setData(value, forKey: key, withAccess: access)
      return true
    } catch {
      return false
    }
  }

  public func setData(_ value: Data, forKey key: String, withAccess access: KeychainAccessOptions? = nil) throws {
    let query = addingAccessGroup(to: [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ])
    let attributes: [String: Any] = [
      kSecValueData as String: value,
      kSecAttrAccessible as String: (access ?? .accessibleWhenUnlocked).value,
    ]

    // Updating in place preserves the old value if the device is locked or the
    // write fails. Delete-then-add can permanently lose a rotated refresh token.
    var status = operations.update(query, attributes)
    if status == errSecItemNotFound {
      let item = query.merging(attributes) { _, new in new }
      status = operations.add(item)
      if status == errSecDuplicateItem {
        status = operations.update(query, attributes)
      }
    }
    guard status == errSecSuccess else { throw KeychainError(status: status) }
  }

  public func get(_ key: String) -> String? {
    guard let data = getData(key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  public func getData(_ key: String) -> Data? {
    try? readData(key)
  }

  /// Only a genuinely absent item is nil; a locked/unavailable keychain throws.
  public func readData(_ key: String) throws -> Data? {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: kCFBooleanTrue as Any,
    ]
    query = addingAccessGroup(to: query)

    let (status, data) = operations.read(query)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw KeychainError(status: status) }
    guard let data else { throw KeychainError(status: errSecDecode) }
    return data
  }

  public func setAccessibility(_ access: KeychainAccessOptions, forKey key: String) {
    let query = addingAccessGroup(to: [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ])
    // Best effort migration of existing items; never delete an unreadable item.
    _ = operations.update(query, [kSecAttrAccessible as String: access.value])
  }

  @discardableResult
  public func delete(_ key: String) -> Bool {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]
    query = addingAccessGroup(to: query)

    return operations.delete(query) == errSecSuccess
  }

  private func addingAccessGroup(to query: [String: Any]) -> [String: Any] {
    guard let accessGroup else { return query }
    var query = query
    query[kSecAttrAccessGroup as String] = accessGroup
    return query
  }
}

public struct KeychainError: Error, Sendable {
  public let status: OSStatus

  public init(status: OSStatus) {
    self.status = status
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
