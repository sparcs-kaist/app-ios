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
    defer { configureTimetableUseCase() }
#if !os(watchOS)
    self.authRepository = AuthRepository(provider: MoyaProvider<AuthTarget>(plugins: [ApplicationNamePlugin()]))
    try await tokenRefreshIfNeeded()

    // access token
    guard let accessToken = tokenStorage.getAccessToken() else {
      return
    }
    let authPlugin = AccessTokenPlugin { _ in
      return accessToken
    }

    // initialise repositories
    self.otlUserRepository = OTLUserRepository(
      provider: MoyaProvider<OTLUserTarget>(plugins: [ApplicationNamePlugin(), authPlugin])
    )
    self.otlTimetableRepository = OTLTimetableRepository(
      provider: MoyaProvider<OTLTimetableTarget>(plugins: [ApplicationNamePlugin(), authPlugin])
    )
    self.userUseCase = TimetableUserUseCase(otlUserRepository: self.otlUserRepository!)
#endif
  }

  // MARK: - Helpers

  private func tokenRefreshIfNeeded() async throws {
    guard let authRepository = self.authRepository else { return }
    // Reuse a valid token instead of refreshing for every widget update.
    if tokenStorage.getAccessToken() != nil, !tokenStorage.isTokenExpired() { return }
    guard let token = try tokenStorage.readRefreshToken() else { return }

    let tokenStorage = self.tokenStorage
    try await AuthRetryConfig.$isRefreshing.withValue(true) {
      try await AuthTokenRefreshCoordinator.shared.refresh(
        refreshToken: token,
        tokenStorage: tokenStorage
      ) {
        try await authRepository.refreshToken(refreshToken: token)
      }
    }
  }

  private func configureTimetableUseCase() {
    if self.otlTimetableRepository == nil {
      self.otlTimetableRepository = OTLTimetableRepository(
        provider: MoyaProvider<OTLTimetableTarget>(plugins: [ApplicationNamePlugin()])
      )
    }

    if let otlTimetableRepository = self.otlTimetableRepository {
      self.timetableUseCase = TimetableUseCaseBackground(
        otlTimetableRepository: otlTimetableRepository,
        cache: TimetableCacheContainer.makeCache()
      )
    }
  }
}
