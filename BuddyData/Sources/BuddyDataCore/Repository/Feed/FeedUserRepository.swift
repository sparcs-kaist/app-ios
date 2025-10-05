//
//  FeedUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class FeedUserRepository: FeedUserRepositoryProtocol {
  private let provider: MoyaProvider<FeedUserTarget>

  public init(provider: MoyaProvider<FeedUserTarget>) {
    self.provider = provider
  }

  public func register(ssoInfo: String) async throws {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    _ = try response.filterSuccessfulStatusCodes()
  }

  public func fetchUser() async throws -> FeedUser {
    let response = try await provider.request(.getUser)
    _ = try response.filterSuccessfulStatusCodes()

    let user: FeedUser = try response.map(FeedUserDTO.self).toModel()

    return user
  }
}
