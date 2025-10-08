//
//  TimetableService.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation
import BuddyDomain
import Moya

public class TimetableService: TimetableServiceProtocol {
  // MARK: - Dependencies
  private let tokenStorage: TokenStorageProtocol = TokenStorage()
  private var authRepository: AuthRepositoryProtocol? = nil
  private var otlUserRepository: OTLUserRepositoryProtocol? = nil
  private var otlTimetableRepository: OTLTimetableRepositoryProtocol? = nil
  private var userUseCase: UserUseCaseProtocol? = nil
  public var timetableUseCase: TimetableUseCaseBackgroundProtocol? = nil

  public init() {

  }

  public func setup() async throws {
    guard let refreshToken = tokenStorage.getRefreshToken() else { return }

    // refresh token
    self.authRepository = AuthRepository(provider: MoyaProvider<AuthTarget>())
    try await tokenRefresh(refreshToken)

    // access token
    guard let accessToken = tokenStorage.getAccessToken() else { return }
    let authPlugin = AccessTokenPlugin { _ in
      return accessToken
    }

    // initialise repositories
    self.otlUserRepository = OTLUserRepository(
      provider: MoyaProvider<OTLUserTarget>(plugins: [authPlugin])
    )
    self.otlTimetableRepository = OTLTimetableRepository(
      provider: MoyaProvider<OTLTimetableTarget>(plugins: [authPlugin])
    )
    self.userUseCase = TimetableUserUseCase(otlUserRepository: self.otlUserRepository!)

    self.timetableUseCase = TimetableUseCaseBackground(
      userUseCase: self.userUseCase!,
      otlTimetableRepository: self.otlTimetableRepository!
    )
    try await self.timetableUseCase!.load()
  }

  // MARK: - Helpers

  private func tokenRefresh(_ token: String) async throws {
    guard self.authRepository != nil else { return }

    let tokenResponse: TokenResponse = try await self.authRepository!.refreshToken(
      refreshToken: token
    )

    tokenStorage
      .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
  }
}
