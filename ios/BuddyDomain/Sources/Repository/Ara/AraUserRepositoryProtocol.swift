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
}
