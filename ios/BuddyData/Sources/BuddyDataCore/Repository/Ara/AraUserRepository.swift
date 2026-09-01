//
//  AraUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class AraUserRepository: AraUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<AraUserTarget>

  public init(provider: MoyaProvider<AraUserTarget>) {
    self.provider = provider
  }

  public func register(ssoInfo: String) async throws -> AraSignInResponse {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    let _ = try response.filterSuccessfulStatusCodes()
    let userInfo: AraSignInResponse = try response.map(AraSignInResponseDTO.self).toModel()

    return userInfo
  }

  public func agreeTOS(userID: Int) async throws {
    let response = try await provider.request(.agreeTOS(userID: userID))
    _ = try response.filterSuccessfulStatusCodes()
  }
  
  public func fetchUser() async throws -> AraUser {
    let response = try await provider.request(.fetchMe)
    _ = try response.filterSuccessfulStatusCodes()
    let userInfo: AraUser = try response.map(AraUserDTO.self).toModel()
    
    return userInfo
  }
  
  public func updateMe(id: Int, params: [String: Any]) async throws {
    let response = try await provider.request(.updateUser(userID: id, params: params))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
