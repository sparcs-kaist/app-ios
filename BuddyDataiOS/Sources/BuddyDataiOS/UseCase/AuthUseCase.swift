//
//  AuthUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine
import Observation
import BuddyDomain

@Observable
public final class AuthUseCase: AuthUseCaseProtocol, @unchecked Sendable {
  private let authenticationService: AuthenticationServiceProtocol
  private let tokenStorage: TokenStorageProtocol
  private let araUserRepository: AraUserRepositoryProtocol?
  private let feedUserRepository: FeedUserRepositoryProtocol
  private let otlUserRepository: OTLUserRepositoryProtocol

  private let _isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
  public var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    _isAuthenticatedSubject.eraseToAnyPublisher()
  }

  // Timer Properties
  private var refreshTimer: Timer?
  // Avoid collision
  private var isRefreshing = false

  public init(
    authenticationService: AuthenticationServiceProtocol,
    tokenStorage: TokenStorageProtocol,
    araUserRepository: AraUserRepositoryProtocol?,
    feedUserRepository: FeedUserRepositoryProtocol,
    otlUserRepository: OTLUserRepositoryProtocol
  ) {
    self.authenticationService = authenticationService
    self.tokenStorage = tokenStorage
    self.araUserRepository = araUserRepository
    self.feedUserRepository = feedUserRepository
    self.otlUserRepository = otlUserRepository

    let hasValidAccessToken = tokenStorage.getAccessToken() != nil && !tokenStorage.isTokenExpired()
    let hasRefreshToken = tokenStorage.getRefreshToken() != nil
    _isAuthenticatedSubject.value = hasValidAccessToken || hasRefreshToken
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
          try? await self?.refreshAccessToken(force: true)
        }
      }
    }
  }

  private func cancelRefreshTimer() {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }

  public func getAccessToken() -> String? {
    if tokenStorage.isTokenExpired() {
      print("[AuthUseCase] Access token is expired. Attempting to refresh...")
      // If the token is expired, return nil. Caller should invoke getValidAccessToken() to attempt refresh asynchronously.
      return nil
    }
    return tokenStorage.getAccessToken()
  }
  
  public func getValidAccessToken() async throws -> String {
    if tokenStorage.isTokenExpired() {
      print("[AuthUseCase] Access token is expired. Refreshing...")
      try await refreshAccessToken(force: false)
    }

    guard let accessToken = tokenStorage.getAccessToken() else {
      throw AuthUseCaseError.noAccessToken
    }

    return accessToken
  }

  public func refreshAccessToken(force: Bool) async throws {
    if isRefreshing {
      print("[AuthUseCase] Already refreshing, skipping duplicate call.")
      return
    }
    isRefreshing = true
    if let accessToken = tokenStorage.getAccessToken(), !tokenStorage.isTokenExpired(), !force {
      print("[AuthUseCase] Access token is still valid. No refresh needed.")
      print("AccessToken: \(accessToken)")
      scheduleRefreshTimer() // reset timer on valid
      isRefreshing = false
      return
    }

    guard let currentRefreshToken = tokenStorage.getRefreshToken() else {
      // No refresh token found, sign out.
      tokenStorage.clearTokens()
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
      print("[AuthUseCase] Successfully refreshed access token.")
      scheduleRefreshTimer() // set timer on success
      isRefreshing = false
    } catch {
      print("[AuthUseCase] Token refresh failed. \(error.localizedDescription)")
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

  public func signIn() async throws {
    guard let araUserRepository else { return }
    do {
      let tokenResponse: SignInResponse = try await authenticationService.authenticate()
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)

      // MARK: Sign up Ara
      let userInfo: AraSignInResponse = try await araUserRepository.register(ssoInfo: tokenResponse.ssoInfo)
      try? await araUserRepository.agreeTOS(userID: userInfo.userID)

      // MARK: Sign up Feed
      try await self.feedUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

      // MARK: Sign up OTL
      try await self.otlUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

      _isAuthenticatedSubject.value = true
      print("[AuthUseCase] Signed In")
      scheduleRefreshTimer() // set timer on success
    } catch {
      tokenStorage.clearTokens()
      _isAuthenticatedSubject.value = false
      print(error)
      cancelRefreshTimer()
      throw AuthUseCaseError.signInFailed(error)
    }
  }

  public func signOut() async throws {
    tokenStorage.clearTokens()
    _isAuthenticatedSubject.value = false
    cancelRefreshTimer()
    print("[AuthUseCase] Signed Out")
  }
}

