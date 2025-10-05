//
//  OTLUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

protocol OTLUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws
  func fetchUser() async throws -> OTLUser
}

final class OTLUserRepository: OTLUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLUserTarget>

  init(provider: MoyaProvider<OTLUserTarget>) {
    self.provider = provider
  }

  func register(ssoInfo: String) async throws {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func fetchUser() async throws -> OTLUser {
    let response = try await provider.request(.fetchUserInfo)
    let result = try response.map(OTLUserDTO.self).toModel()

    return result
  }
}
