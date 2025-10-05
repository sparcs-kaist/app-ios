//
//  FeedUserRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol FeedUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws
  func fetchUser() async throws -> FeedUser
}
