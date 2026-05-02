//
//  AuthUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import UIKit
import Combine
import Observation
import Synchronization
import BuddyDomain
import BuddyDataCore
import WidgetKit

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

  private struct RefreshState: Sendable {
    var task: Task<Void, Error>?
    var lastFailure: Date?
  }
  
  private let refreshState = Mutex<RefreshState>(RefreshState())
  private let refreshCooldown: TimeInterval = 10

  // Touched only from MainActor (see scheduleRefreshTimer / cancelRefreshTimer).
  private var refreshTimer: Timer?

  // Called after a successful token refresh
  public var onTokenRefresh: (() -> Void)?
  // Foreground observer
  private var foregroundObserver: (any NSObjectProtocol)?

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
  private func observeForeground() {
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
  private func scheduleRefreshTimer() {
    // Timer scheduled from inside a Task body would never fire. Hop to MainActor.
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

  private func cancelRefreshTimer() {
    Task { @MainActor [weak self] in
      self?.refreshTimer?.invalidate()
      self?.refreshTimer = nil
    }
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

  private enum RefreshAction {
    case awaitExisting(Task<Void, Error>)
    case cooldown
    case noopValid
    case awaitNew(Task<Void, Error>)
  }

  public func refreshAccessToken(force: Bool) async throws {
    let action: RefreshAction = refreshState.withLock { state in
      if let existingTask = state.task {
        return .awaitExisting(existingTask)
      }

      if let lastFailure = state.lastFailure,
         Date().timeIntervalSince(lastFailure) < refreshCooldown {
        return .cooldown
      }

      if tokenStorage.getAccessToken() != nil, !tokenStorage.isTokenExpired(), !force {
        return .noopValid
      }

      let newTask = Task { [weak self] in
        guard let self else { return }
        defer {
          self.refreshState.withLock { $0.task = nil }
        }

        guard let currentRefreshToken = self.tokenStorage.getRefreshToken() else {
          // No refresh token found, sign out.
          self.tokenStorage.clearTokens()
          self._isAuthenticatedSubject.value = false
          self.cancelRefreshTimer()
          throw AuthUseCaseError.refreshFailed(NSError(domain: "AuthUseCase", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"]))
        }

        do {
          // Mark the in-flight refresh on the task-local
          let tokenResponse: TokenResponse = try await AuthRetryConfig.$isRefreshing.withValue(true) {
            try await self.authenticationService.refreshAccessToken(
              refreshToken: currentRefreshToken
            )
          }
          self.tokenStorage
            .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
          self._isAuthenticatedSubject.value = true
          self.refreshState.withLock { $0.lastFailure = nil }
          print("[AuthUseCase] Successfully refreshed access token.")
          self.scheduleRefreshTimer() // set timer on success
          self.onTokenRefresh?()
        } catch {
          print("[AuthUseCase] Token refresh failed. \(error.localizedDescription)")
          self.refreshState.withLock { $0.lastFailure = Date() }
          // Only clear tokens on auth error (401), not on network/decoding errors
          let isAuthError: Bool
          if let networkError = error as? NetworkError, case .unauthorized = networkError {
            isAuthError = true
          } else {
            isAuthError = false
          }
          if isAuthError {
            self.tokenStorage.clearTokens()
            self._isAuthenticatedSubject.value = false
            self.cancelRefreshTimer()
          }
          throw AuthUseCaseError.refreshFailed(error)
        }
      }
      state.task = newTask
      return .awaitNew(newTask)
    }

    switch action {
    case .awaitExisting(let task):
      try await task.value
    case .cooldown:
      throw AuthUseCaseError.refreshFailed(
        NSError(domain: "AuthUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Refresh on cooldown"])
      )
    case .noopValid:
      print("[AuthUseCase] Access token is still valid. No refresh needed.")
      scheduleRefreshTimer() // reset timer on valid
    case .awaitNew(let task):
      try await task.value
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
		WidgetCenter.shared.reloadAllTimelines()
    tokenStorage.clearTokens()
    _isAuthenticatedSubject.value = false
    cancelRefreshTimer()
    print("[AuthUseCase] Signed Out")
  }
}
