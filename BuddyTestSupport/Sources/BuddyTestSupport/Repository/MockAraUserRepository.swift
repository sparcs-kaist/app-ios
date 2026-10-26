//
//  MockAraUserRepository.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 26/10/2026.
//

import Foundation
import BuddyDomain

public final class MockAraUserRepository: AraUserRepositoryProtocol, @unchecked Sendable {
  /// What `blockUser` and `unblockUser` do.
  public var blockResult: Result<Void, Error> = .success(())

  /// What `fetchBlockedUsers` returns, or the error it throws.
  public var fetchBlockedUsersResult: Result<[AraBlockedUser], Error> = .success([])

  public private(set) var blockedUserIDs: [Int] = []
  public private(set) var unblockedUserIDs: [Int] = []

  public init() { }

  public func register(ssoInfo: String) async throws -> AraSignInResponse {
    throw TestError.notConfigured
  }

  public func agreeTOS(userID: Int) async throws { }

  public func fetchUser() async throws -> AraUser {
    throw TestError.notConfigured
  }

  public func updateMe(id: Int, params: [String: Any]) async throws { }

  public func blockUser(userID: Int) async throws {
    blockedUserIDs.append(userID)
    try blockResult.get()
  }

  public func unblockUser(userID: Int) async throws {
    unblockedUserIDs.append(userID)
    try blockResult.get()
  }

  public func fetchBlockedUsers() async throws -> [AraBlockedUser] {
    try fetchBlockedUsersResult.get()
  }
}
