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

protocol AraUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws -> AraSignInResponseDTO
  func agreeTOS(userID: Int) async throws
  func fetchUser() async throws -> AraUser
  func updateMe(id: Int, params: [String: Any]) async throws
}

final class AraUserRepository: AraUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<AraUserTarget>

  init(provider: MoyaProvider<AraUserTarget>) {
    self.provider = provider
  }

  func register(ssoInfo: String) async throws -> AraSignInResponseDTO {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    let _ = try response.filterSuccessfulStatusCodes()
    let userInfo: AraSignInResponseDTO = try response.map(AraSignInResponseDTO.self)

    return userInfo
  }

  func agreeTOS(userID: Int) async throws {
    let response = try await provider.request(.agreeTOS(userID: userID))
    _ = try response.filterSuccessfulStatusCodes()
  }
  
  func fetchUser() async throws -> AraUser {
    let response = try await provider.request(.fetchMe)
    _ = try response.filterSuccessfulStatusCodes()
    let userInfo: AraUser = try response.map(AraUserDTO.self).toModel()
    
    return userInfo
  }
  
  func updateMe(id: Int, params: [String: Any]) async throws {
    let response = try await provider.request(.updateUser(userID: id, params: params))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
