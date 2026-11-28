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
  public var fetchLectureFriendsResult: Result<LectureFriends, Error> = .success(
    LectureFriends(sameLecture: [], sameCourse: [])
  )
  public var fetchSharedTimetableTermsResult: Result<[FriendTimetableTerm], Error> = .success([])
  /// Keyed by term; a term with no entry fails with `NetworkError.notFound`.
  public var sharedTimetables: [FriendTimetableTerm: Result<FriendTimetable, Error>] = [:]
  public private(set) var requestedTerms: [FriendTimetableTerm] = []
  public private(set) var addedCodes: [String] = []
  public private(set) var fetchMyCodeCallCount = 0

  public init() { }

  public func fetchFriends() async throws -> FriendList {
    try fetchFriendsResult.get()
  }

  public func addFriend(code: String) async throws {
    addedCodes.append(code)
    try addFriendResult.get()
  }

  public func deleteFriend(id: Int) async throws {
    try deleteFriendResult.get()
  }

  public func setFavorite(id: Int, isFavorite: Bool) async throws {
    try setFavoriteResult.get()
  }

  public func fetchMyCode() async throws -> String {
    fetchMyCodeCallCount += 1
    return try fetchMyCodeResult.get()
  }

  public func fetchLectureFriends(lectureID: Int) async throws -> LectureFriends {
    try fetchLectureFriendsResult.get()
  }

  public func fetchSharedTimetableTerms(friendID: Int) async throws -> [FriendTimetableTerm] {
    try fetchSharedTimetableTermsResult.get()
  }

  public func fetchSharedTimetable(friendID: Int, term: FriendTimetableTerm) async throws -> FriendTimetable {
    requestedTerms.append(term)
    guard let result = sharedTimetables[term] else { throw NetworkError.notFound }
    return try result.get()
  }
}
