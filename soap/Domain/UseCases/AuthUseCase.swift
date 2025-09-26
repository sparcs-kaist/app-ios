//
//  AuthUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine
import Observation

@MainActor
protocol AuthUseCaseProtocol {
  var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
  func signIn() async throws
  func signOut() async throws
  func getAccessToken() -> String?
  func getValidAccessToken() async throws -> String
  func refreshAccessTokenIfNeeded() async throws
}


@Observable
class AuthUseCase: AuthUseCaseProtocol {
  private let authenticationService: AuthenticationServiceProtocol
  private let tokenStorage: TokenStorageProtocol
  private let araUserRepository: AraUserRepositoryProtocol
  private let feedUserRepository: FeedUserRepositoryProtocol

  private let _isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
  var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    _isAuthenticatedSubject.eraseToAnyPublisher()
  }

  // Timer Properties
  private var refreshTimer: Timer?
  // Avoid collision
  private var isRefreshing = false

  init(
    authenticationService: AuthenticationServiceProtocol,
    tokenStorage: TokenStorageProtocol,
    araUserRepository: AraUserRepositoryProtocol,
    feedUserRepository: FeedUserRepositoryProtocol
  ) {
    self.authenticationService = authenticationService
    self.tokenStorage = tokenStorage
    self.araUserRepository = araUserRepository
    self.feedUserRepository = feedUserRepository

    _isAuthenticatedSubject.value = tokenStorage.getAccessToken() != nil && !tokenStorage.isTokenExpired()
    scheduleRefreshTimer()
  }

  // MARK: - Timer Scheduling
  private func scheduleRefreshTimer() {
    refreshTimer?.invalidate()
    guard let expirationDate = tokenStorage.getTokenExpirationDate() else { return }
    let buffer: TimeInterval = 5 * 60 // 5 min
    let fireDate = expirationDate.addingTimeInterval(-buffer)
    let interval = max(fireDate.timeIntervalSinceNow, 0)
    if interval > 0 {
      refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
        Task { [weak self] in
          try? await self?.refreshAccessTokenIfNeeded()
        }
      }
    }
  }

  private func cancelRefreshTimer() {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }

  func getAccessToken() -> String? {
    if tokenStorage.isTokenExpired() {
      logger.warning("[AuthUseCase] Access token is expired. Attempting to refresh...")
      // If the token is expired, return nil. Caller should invoke getValidAccessToken() to attempt refresh asynchronously.
      return nil
    }
    return tokenStorage.getAccessToken()
  }
  
  func getValidAccessToken() async throws -> String {
    if tokenStorage.isTokenExpired() {
      logger.info("[AuthUseCase] Access token is expired. Refreshing...")
      try await refreshAccessTokenIfNeeded()
    }

    guard let accessToken = tokenStorage.getAccessToken() else {
      throw AuthUseCaseError.noAccessToken
    }

    return accessToken
  }

  func refreshAccessTokenIfNeeded() async throws {
    if isRefreshing {
      logger.info("[AuthUseCase] Already refreshing, skipping duplicate call.")
      return
    }
    isRefreshing = true
    if let accessToken = tokenStorage.getAccessToken(), !tokenStorage.isTokenExpired() {
      logger.info("[AuthUseCase] Access token is still valid. No refresh needed.")
      logger.debug("AccessToken: \(accessToken)")
      scheduleRefreshTimer() // reset timer on valid
      isRefreshing = false
      return
    }

    guard let currentRefreshToken = tokenStorage.getRefreshToken() else {
      // No refresh token found, sign out.
      _isAuthenticatedSubject.value = false
      cancelRefreshTimer()
      isRefreshing = false
      throw AuthUseCaseError.refreshFailed(NSError(domain: "AuthUseCase", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"]))
    }

    // Attempts to refresh token using refresh token from Keychain
    do {
      let tokenResponse = try await authenticationService.refreshAccessToken(
        refreshToken: currentRefreshToken
      )
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
      _isAuthenticatedSubject.value = true
      logger.info("[AuthUseCase] Successfully refreshed access token.")
      scheduleRefreshTimer() // set timer on success
      isRefreshing = false
    } catch {
      logger.error("[AuthUseCase] Token refresh failed. \(error.localizedDescription)")
      // network error, do not remove tokens on decoding error. only when 401
      let nsError = error as NSError
      let isAuthError = nsError.domain == NSURLErrorDomain ? false : (nsError.code == 401)
      if isAuthError {
        tokenStorage.clearTokens()
        _isAuthenticatedSubject.value = false
        cancelRefreshTimer()
      }
      isRefreshing = false
      throw AuthUseCaseError.refreshFailed(error)
    }
  }

  func signIn() async throws {
    do {
      let tokenResponse: SignInResponseDTO = try await authenticationService.authenticate()
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)

      // MARK: Sign up Ara
      let userInfo: AraSignInResponseDTO = try await self.araUserRepository.register(ssoInfo: tokenResponse.ssoInfo)
      try? await self.araUserRepository.agreeTOS(userID: userInfo.userID)

      // MARK: Sign up Feed
      try await self.feedUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

      _isAuthenticatedSubject.value = true
      logger.info("[AuthUseCase] Signed In")
      scheduleRefreshTimer() // set timer on success
    } catch {
      tokenStorage.clearTokens()
      _isAuthenticatedSubject.value = false
      logger.error(error)
      cancelRefreshTimer()
      throw AuthUseCaseError.signInFailed(error)
    }
  }

  func signOut() async throws {
    tokenStorage.clearTokens()
    _isAuthenticatedSubject.value = false
    cancelRefreshTimer()
    logger.info("[AuthUseCase] Signed Out")
  }
}

