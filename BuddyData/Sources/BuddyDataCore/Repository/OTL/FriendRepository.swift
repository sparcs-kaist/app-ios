//
//  FriendRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class FriendRepository: FriendRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<FriendTarget>

  public init(provider: MoyaProvider<FriendTarget>) {
    self.provider = provider
  }

  public func fetchFriends() async throws -> FriendList {
    let response = try await provider.request(.fetchFriends)
    return try response.map(FriendListResponseDTO.self).toModel()
  }

  /// Turns the server's refusals into `AddFriendError`s the user can act on.
  public func addFriend(code: String) async throws {
    let response = try await provider.requestAllowingFailure(.addFriend(code: code))
    switch response.statusCode {
    case 200...299:
      return
    case 400:
      let body = try? response.map(APIErrorCodeDTO.self)
      throw body?.code == "SELF_FRIENDSHIP" ? AddFriendError.ownCode : AddFriendError.invalidCode
    case 429:
      let retryAfter = response.response?.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
      throw AddFriendError.tooManyAttempts(retryAfter: retryAfter)
    case 503:
      throw AddFriendError.unavailable
    case 404:
      throw NetworkError.notFound
    default:
      throw NetworkError.serverError(statusCode: response.statusCode)
    }
  }

  public func deleteFriend(id: Int) async throws {
    let response = try await provider.request(.deleteFriend(id: id))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func setFavorite(id: Int, isFavorite: Bool) async throws {
    let response = try await provider.request(.setFavorite(id: id, isFavorite: isFavorite))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func fetchMyCode() async throws -> String {
    let response = try await provider.request(.fetchMyCode)
    return try response.map(FriendCodeResponseDTO.self).code
  }

  public func fetchLectureFriends(lectureID: Int) async throws -> LectureFriends {
    let response = try await provider.request(.fetchLectureFriends(lectureID: lectureID))
    return try response.map(LectureFriendsDTO.self).toModel()
  }

  public func fetchSharedTimetableTerms(friendID: Int) async throws -> [FriendTimetableTerm] {
    let response = try await provider.request(.fetchSharedSemesters(friendID: friendID))
    return try response.map(FriendSharedSemestersDTO.self).toModel()
  }

  public func fetchSharedTimetable(friendID: Int, term: FriendTimetableTerm) async throws -> FriendTimetable {
    let response = try await provider.request(
      .fetchSharedTimetable(friendID: friendID, year: term.year, semester: term.semester.intValue)
    )
    return try response.map(FriendSharedTimetableDTO.self).toModel(friendID: friendID, term: term)
  }
}
