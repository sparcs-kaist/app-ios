//
//  AraUserRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol AraUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws -> AraSignInResponse
  func agreeTOS(userID: Int) async throws
  func fetchUser() async throws -> AraUser
  func updateMe(id: Int, params: [String: Any]) async throws
  /// Hides the user's posts and comments from the signed-in user. Ara allows 10 blocks a day,
  /// and answers a further one with 403.
  func blockUser(userID: Int) async throws
  func unblockUser(userID: Int) async throws
  /// Everyone the signed-in user has blocked.
  func fetchBlockedUsers() async throws -> [AraBlockedUser]
}
