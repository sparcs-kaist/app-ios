//
//  FeedUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol FeedUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws
  func getUser() async throws -> FeedUser
}

final class FeedUserRepository: FeedUserRepositoryProtocol {
  private let provider: MoyaProvider<FeedUserTarget>

  init(provider: MoyaProvider<FeedUserTarget>) {
    self.provider = provider
  }

  func register(ssoInfo: String) async throws {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func getUser() async throws -> FeedUser {
    let response = try await provider.request(.getUser)
    _ = try response.filterSuccessfulStatusCodes()

    let user: FeedUser = try response.map(FeedUserDTO.self).toModel()

    return user
  }
}
