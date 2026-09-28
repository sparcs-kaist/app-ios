//
//  FriendUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

public protocol FriendUseCaseProtocol: Sendable {
  func fetchFriends() async throws -> FriendList
  func addFriend(code: String) async throws
  func deleteFriend(id: Int) async throws
  func setFavorite(id: Int, isFavorite: Bool) async throws
  func fetchMyCode() async throws -> String
}
