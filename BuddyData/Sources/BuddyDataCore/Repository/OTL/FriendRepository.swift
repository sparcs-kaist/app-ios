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

  public func addFriend(code: String) async throws {
    let response = try await provider.request(.addFriend(code: code))
    _ = try response.filterSuccessfulStatusCodes()
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
}
