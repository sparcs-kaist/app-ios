//
//  AuthUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import UIKit
import Combine
import BuddyDomain
import BuddyDataCore
import WidgetKit

public actor AuthUseCase: AuthUseCaseProtocol {
  private let authenticationService: AuthenticationServiceProtocol
  private let tokenStorage: TokenStorageProtocol
  private let araUserRepository: AraUserRepositoryProtocol?
  private let feedUserRepository: FeedUserRepositoryProtocol?
  private let otlUserRepository: OTLUserRepositoryProtocol?

  // `CurrentValueSubject` is internally thread-safe, so it is marked
  // `nonisolated(unsafe)` to let the auth-state publisher be read and observed
  // from any isolation domain.
  private nonisolated(unsafe) let _isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
  public nonisolated var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    _isAuthenticatedSubject.eraseToAnyPublisher()
  }

  // In-flight refresh coordination. Because the check-and-assign of
  // `refreshTask` in `refreshAccessToken(force:)` runs without an intervening
  // `await`, actor isolation guarantees only one refresh task is ever created —
  // replacing the previous `Mutex`.
  private var refreshTask: Task<Void, Error>?
  private var lastFailure: Date?
  private let refreshCooldown: TimeInterval = 10

  // A `Timer` needs a run loop, so it is confined to the MainActor.
  @MainActor private var refreshTimer: Timer?

  // Called after a successful token refresh. Assigned once at registration
  // time, so `nonisolated(unsafe)` permits the synchronous assignment.
  public nonisolated(unsafe) var onTokenRefresh: (() -> Void)?

  // Foreground observer, set once in `init` and removed in `deinit`.
  private nonisolated(unsafe) var foregroundObserver: (any NSObjectProtocol)?

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
    observeForeground()
  }

  deinit {
    if let foregroundObserver {
      NotificationCenter.default.removeObserver(foregroundObserver)
    }
  }

  // MARK: - Foreground Refresh
  private nonisolated func observeForeground() {
    foregroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { [weak self] in
        guard let self, self._isAuthenticatedSubject.value else { return }
        try? await self.refreshAccessToken(force: false)
      }
    }
  }

  // MARK: - Timer Scheduling
  private nonisolated func scheduleRefreshTimer() {
    // Timers must be scheduled on a run loop, so hop to the MainActor.
    Task { @MainActor [weak self] in
      guard let self else { return }
      self.refreshTimer?.invalidate()
      guard let expirationDate = self.tokenStorage.getTokenExpirationDate() else { return }
      let buffer: TimeInterval = 5 * 60 // 5 min
      let fireDate = expirationDate.addingTimeInterval(-buffer)
      let interval = max(fireDate.timeIntervalSinceNow, 0)
      guard interval > 0 else { return }
      self.refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
        Task { [weak self] in
          try? await self?.refreshAccessToken(force: true)
        }
      }
    }
  }

  private nonisolated func cancelRefreshTimer() {
    Task { @MainActor [weak self] in
      self?.refreshTimer?.invalidate()
      self?.refreshTimer = nil
    }
  }

  // MARK: - Access Token
  public nonisolated func getAccessToken() -> String? {
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
    // Coalesce concurrent callers onto the in-flight refresh, if any.
    if let refreshTask {
      try await refreshTask.value
      return
    }

    if let lastFailure,
       Date().timeIntervalSince(lastFailure) < refreshCooldown {
      throw AuthUseCaseError.refreshFailed(
        NSError(domain: "AuthUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Refresh on cooldown"])
      )
    }

    if tokenStorage.getAccessToken() != nil, !tokenStorage.isTokenExpired(), !force {
      print("[AuthUseCase] Access token is still valid. No refresh needed.")
      scheduleRefreshTimer() // reset timer on valid
      return
    }

    // No `await` between the nil-check above and this assignment, so actor
    // isolation guarantees a single task is created for concurrent callers.
    let task = Task { [weak self] () throws -> Void in
      guard let self else { return }
      try await self.performTokenRefresh()
    }
    refreshTask = task
    defer { refreshTask = nil }

    try await task.value
  }

  private func performTokenRefresh() async throws {
    guard let currentRefreshToken = tokenStorage.getRefreshToken() else {
      // No refresh token found, sign out.
      tokenStorage.clearTokens()
      _isAuthenticatedSubject.value = false
      cancelRefreshTimer()
      throw AuthUseCaseError.refreshFailed(NSError(domain: "AuthUseCase", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"]))
    }

    do {
      // Mark the in-flight refresh on the task-local
      let tokenResponse: TokenResponse = try await AuthRetryConfig.$isRefreshing.withValue(true) {
        try await self.authenticationService.refreshAccessToken(
          refreshToken: currentRefreshToken
        )
      }
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
      _isAuthenticatedSubject.value = true
      lastFailure = nil
      print("[AuthUseCase] Successfully refreshed access token.")
      scheduleRefreshTimer() // set timer on success
      onTokenRefresh?()
    } catch {
      print("[AuthUseCase] Token refresh failed. \(error.localizedDescription)")
      lastFailure = Date()
      // Only clear tokens on auth error (401), not on network/decoding errors
      let isAuthError: Bool
      if let networkError = error as? NetworkError, case .unauthorized = networkError {
        isAuthError = true
      } else {
        isAuthError = false
      }
      if isAuthError {
        tokenStorage.clearTokens()
        _isAuthenticatedSubject.value = false
        cancelRefreshTimer()
      }
      throw AuthUseCaseError.refreshFailed(error)
    }
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
      WidgetCenter.shared.reloadAllTimelines()
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
    if let container = TimetableCacheContainer.shared {
      TimetableCache(modelContainer: container).clear()
    }
    WidgetCenter.shared.reloadAllTimelines()
    tokenStorage.clearTokens()
    _isAuthenticatedSubject.value = false
    cancelRefreshTimer()
    print("[AuthUseCase] Signed Out")
  }
}
