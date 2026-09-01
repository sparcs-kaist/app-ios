//
//  AuthRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class AuthRepository: AuthRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<AuthTarget>

  public init(provider: MoyaProvider<AuthTarget>) {
    self.provider = provider
  }

  public func requestToken(authorisationCode: String, codeVerifier: String) async throws -> SignInResponse {
    let response = try await self.provider.request(
      .requestTokens(authorisationCode: authorisationCode, codeVerifier: codeVerifier)
    )
    let result = try response.map(SignInResponseDTO.self).toModel()

    return result
  }

  public func refreshToken(refreshToken: String) async throws -> TokenResponse {
    let response = try await self.provider.request(.refreshTokens(refreshToken: refreshToken))
    let result = try response.map(TokenResponseDTO.self).toModel()

    return result
  }
}
