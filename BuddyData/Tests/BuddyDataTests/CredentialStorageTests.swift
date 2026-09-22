import Testing
import Foundation
import Security
@testable import BuddyDataCore

@Suite("Credential storage")
struct CredentialStorageTests {
  @Test func tokenReplacementKeepsTheExistingKeychainItem() throws {
    let backend = TestKeychainBackend()
    let keychain = Keychain(operations: backend.operations)
    try keychain.setData(Data("old-token".utf8), forKey: "token")
    try keychain.setData(Data("new-token".utf8), forKey: "token", withAccess: .accessibleAfterFirstUnlock)

    #expect(try keychain.readData("token") == Data("new-token".utf8))
    #expect(backend.addCount == 1)
    #expect(backend.deleteCount == 0)
    #expect(backend.accessibility == kSecAttrAccessibleAfterFirstUnlock as String)
  }

  @Test func failedWriteLeavesPreviousCredentialsIntact() throws {
    let backend = TestKeychainBackend()
    let keychain = Keychain(operations: backend.operations)
    try keychain.setData(Data("saved-token".utf8), forKey: "token")
    backend.updateError = errSecInteractionNotAllowed

    #expect(throws: KeychainError.self) {
      try keychain.setData(Data("replacement".utf8), forKey: "token")
    }
    #expect(try keychain.readData("token") == Data("saved-token".utf8))
    #expect(backend.deleteCount == 0)
    #expect(backend.addCount == 1)
  }

  @Test func lockedKeychainIsAnErrorInsteadOfAMissingToken() throws {
    let backend = TestKeychainBackend()
    let keychain = Keychain(operations: backend.operations)
    #expect(try keychain.readData("token") == nil)
    backend.readError = errSecInteractionNotAllowed
    #expect(throws: KeychainError.self) { try keychain.readData("token") }
    #expect(backend.deleteCount == 0)
  }

  @Test func existingCredentialsMigrateWithoutChangingTheirValue() throws {
    let backend = TestKeychainBackend()
    let keychain = Keychain(operations: backend.operations)
    try keychain.setData(Data("saved-token".utf8), forKey: "token", withAccess: .accessibleWhenUnlocked)
    keychain.setAccessibility(.accessibleAfterFirstUnlock, forKey: "token")

    #expect(try keychain.readData("token") == Data("saved-token".utf8))
    #expect(backend.accessibility == kSecAttrAccessibleAfterFirstUnlock as String)
    #expect(backend.deleteCount == 0)
  }

}

private final class TestKeychainBackend {
  var value: Data?
  var accessibility: String?
  var updateError: OSStatus?
  var readError: OSStatus?
  var addCount = 0
  var deleteCount = 0

  var operations: Keychain.Operations {
    .init(update: { _, attributes in
      if let error = self.updateError { return error }
      guard self.value != nil else { return errSecItemNotFound }
      if let data = attributes[kSecValueData as String] as? Data { self.value = data }
      if let access = attributes[kSecAttrAccessible as String] as? String { self.accessibility = access }
      return errSecSuccess
    }, add: { item in
      self.addCount += 1
      guard self.value == nil else { return errSecDuplicateItem }
      self.value = item[kSecValueData as String] as? Data
      self.accessibility = item[kSecAttrAccessible as String] as? String
      return errSecSuccess
    }, read: { _ in
      if let error = self.readError { return (error, nil) }
      return (self.value == nil ? errSecItemNotFound : errSecSuccess, self.value)
    }, delete: { _ in
      self.deleteCount += 1
      self.value = nil
      return errSecSuccess
    })
  }
}
