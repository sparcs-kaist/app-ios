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
  private let feedUserRepository: FeedUserRepositoryProtocol?
  private let otlUserRepository: OTLUserRepositoryProtocol?

  private let _isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
  public var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    _isAuthenticatedSubject.eraseToAnyPublisher()
  }

  // Timer Properties
  private var refreshTimer: Timer?
  // Coalesce concurrent refresh calls
  private var refreshTask: Task<Void, Error>?

  public init(
    authenticationService: AuthenticationServiceProtocol,
    tokenStorage: TokenStorageProtocol,
    araUserRepository: AraUserRepositoryProtocol?,
    feedUserRepository: FeedUserRepositoryProtocol?,
    otlUserRepository: OTLUserRepositoryProtocol?
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
    // If a refresh is already in-flight, coalesce by awaiting it
    if let existingTask = refreshTask {
      try await existingTask.value
      return
    }

    if tokenStorage.getAccessToken() != nil, !tokenStorage.isTokenExpired(), !force {
      print("[AuthUseCase] Access token is still valid. No refresh needed.")
      scheduleRefreshTimer() // reset timer on valid
      return
    }

    let task = Task { [weak self] in
      guard let self else { return }
      defer { self.refreshTask = nil }

      guard let currentRefreshToken = self.tokenStorage.getRefreshToken() else {
        // No refresh token found, sign out.
        self.tokenStorage.clearTokens()
        self._isAuthenticatedSubject.value = false
        self.cancelRefreshTimer()
        throw AuthUseCaseError.refreshFailed(NSError(domain: "AuthUseCase", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"]))
      }

      // Attempts to refresh token using refresh token from Keychain
      do {
        let tokenResponse = try await self.authenticationService.refreshAccessToken(
          refreshToken: currentRefreshToken
        )
        self.tokenStorage
          .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
        self._isAuthenticatedSubject.value = true
        print("[AuthUseCase] Successfully refreshed access token.")
        self.scheduleRefreshTimer() // set timer on success
      } catch {
        print("[AuthUseCase] Token refresh failed. \(error.localizedDescription)")
        // network error, do not remove tokens on decoding error. only when 401
        let nsError = error as NSError
        let isAuthError = nsError.domain == NSURLErrorDomain ? false : (nsError.code == 401)
        if isAuthError {
          self.tokenStorage.clearTokens()
          self._isAuthenticatedSubject.value = false
          self.cancelRefreshTimer()
        }
        throw AuthUseCaseError.refreshFailed(error)
      }
    }
    refreshTask = task
    try await task.value
  }

  public func signIn() async throws {
    guard let araUserRepository, let feedUserRepository, let otlUserRepository else { return }
    do {
      let tokenResponse: SignInResponse = try await authenticationService.authenticate()
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)

      // MARK: Sign up Ara
      let userInfo: AraSignInResponse = try await araUserRepository.register(ssoInfo: tokenResponse.ssoInfo)
      try? await araUserRepository.agreeTOS(userID: userInfo.userID)

      // MARK: Sign up Feed
      try await feedUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

      // MARK: Sign up OTL
      try await otlUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

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

