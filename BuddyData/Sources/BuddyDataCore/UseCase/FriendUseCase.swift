//
//  FriendUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import BuddyDomain

public final class FriendUseCase: FriendUseCaseProtocol {
  private let friendRepository: FriendRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  public init(
    friendRepository: FriendRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.friendRepository = friendRepository
    self.crashlyticsService = crashlyticsService
  }

  public func fetchFriends() async throws -> FriendList {
    try await execute(operation: "fetchFriends") {
      try await friendRepository.fetchFriends()
    }
  }

  public func addFriend(code: String) async throws {
    try await execute(operation: "addFriend") {
      try await friendRepository.addFriend(code: code)
    }
  }

  public func deleteFriend(id: Int) async throws {
    try await execute(operation: "deleteFriend") {
      try await friendRepository.deleteFriend(id: id)
    }
  }

  public func setFavorite(id: Int, isFavorite: Bool) async throws {
    try await execute(operation: "setFavorite") {
      try await friendRepository.setFavorite(id: id, isFavorite: isFavorite)
    }
  }

  public func fetchMyCode() async throws -> String {
    try await execute(operation: "fetchMyCode") {
      try await friendRepository.fetchMyCode()
    }
  }

  public func fetchLectureFriends(lectureID: Int) async throws -> LectureFriends {
    try await execute(operation: "fetchLectureFriends") {
      try await friendRepository.fetchLectureFriends(lectureID: lectureID)
    }
  }

  public func fetchSharedTimetableTerms(friendID: Int) async throws -> [FriendTimetableTerm] {
    try await execute(operation: "fetchSharedTimetableTerms") {
      try await friendRepository.fetchSharedTimetableTerms(friendID: friendID)
    }
  }

  public func fetchSharedTimetable(friendID: Int, term: FriendTimetableTerm) async throws -> FriendTimetable {
    try await execute(operation: "fetchSharedTimetable") {
      try await friendRepository.fetchSharedTimetable(friendID: friendID, term: term)
    }
  }

  private func execute<T>(operation: String, _ action: () async throws -> T) async throws -> T {
    do {
      return try await action()
    } catch let error as AddFriendError {
      // The user's to fix, not a fault to record.
      throw error
    } catch {
      crashlyticsService?.record(
        error: error,
        context: CrashContext(feature: "Friend", metadata: ["operation": operation])
      )
      throw error
    }
  }
}
