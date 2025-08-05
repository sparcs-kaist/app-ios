//
//  TaxiUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

@preconcurrency
import Moya

protocol TaxiUserRepositoryProtocol: Sendable {
  func fetchUser() async throws -> TaxiUser
}

final class TaxiUserRepository: TaxiUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<TaxiUserTarget>

  init(provider: MoyaProvider<TaxiUserTarget>) {
    self.provider = provider
  }

  func fetchUser() async throws -> TaxiUser {
    let response = try await provider.request(.fetchUserInfo)
    let result = try response.map(TaxiUserDTO.self).toModel()

    return result
  }
}
