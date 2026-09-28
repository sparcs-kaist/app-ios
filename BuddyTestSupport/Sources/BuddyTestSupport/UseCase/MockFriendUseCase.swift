//
//  MockFriendUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation
import BuddyDomain

public final class MockFriendUseCase: FriendUseCaseProtocol, @unchecked Sendable {
  public var fetchFriendsResult: Result<FriendList, Error> = .success(
    FriendList(checkedAt: nil, friends: Friend.mockList)
  )
  public var addFriendResult: Result<Void, Error> = .success(())
  public var deleteFriendResult: Result<Void, Error> = .success(())
  public var setFavoriteResult: Result<Void, Error> = .success(())
  public var fetchMyCodeResult: Result<String, Error> = .success("ACD347")

  public init() { }

  public func fetchFriends() async throws -> FriendList {
    try fetchFriendsResult.get()
  }

  public func addFriend(code: String) async throws {
    try addFriendResult.get()
  }

  public func deleteFriend(id: Int) async throws {
    try deleteFriendResult.get()
  }

  public func setFavorite(id: Int, isFavorite: Bool) async throws {
    try setFavoriteResult.get()
  }

  public func fetchMyCode() async throws -> String {
    try fetchMyCodeResult.get()
  }
}
