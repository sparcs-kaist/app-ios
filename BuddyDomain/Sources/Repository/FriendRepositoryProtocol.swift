//
//  FriendRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

public protocol FriendRepositoryProtocol: Sendable {
  func fetchFriends() async throws -> FriendList
  func addFriend(code: String) async throws
  func deleteFriend(id: Int) async throws
  func setFavorite(id: Int, isFavorite: Bool) async throws
  func fetchMyCode() async throws -> String
  /// The semesters the friend has a timetable for, newest first.
  func fetchSharedTimetableTerms(friendID: Int) async throws -> [FriendTimetableTerm]
  /// The timetable the friend shares for `term`, or their enrolled lectures when they share none.
  func fetchSharedTimetable(friendID: Int, term: FriendTimetableTerm) async throws -> FriendTimetable
}
