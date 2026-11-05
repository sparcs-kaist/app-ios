//
//  AuthUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import UIKit
import Combine
import os
import BuddyDomain
import BuddyDataCore
import Factory
import WidgetKit

private let logger = Logger(subsystem: "org.sparcs.soap", category: "Auth")

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
  public nonisolated var isAuthenticated: Bool {
    _isAuthenticatedSubject.value
  }

  // In-flight refresh coordination. Because the check-and-assign of
  // `refreshTask` in `refreshAccessToken(force:)` runs without an intervening
  // `await`, actor isolation guarantees only one refresh task is ever created —
  // replacing the previous `Mutex`.
  private var refreshTask: Task<Void, Error>?
  private var lastFailure: Date?
  private let refreshCooldown: TimeInterval
  // The refresh token the server last rejected. It ends the session only if the
  // server rejects it a second time.
  private var rejectedRefreshToken: String?

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
    otlUserRepository: OTLUserRepositoryProtocol?,
    refreshCooldown: TimeInterval = 10
  ) {
    self.refreshCooldown = refreshCooldown
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
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { [weak self] in
        // Re-check storage after activation, including a launch while the
        // keychain was locked. A failed read must not leave the app signed out.
        try? await self?.refreshAccessToken(force: false)
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
          try? await self?.refreshAccessToken(force: false)
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
      logger.debug("Access token is expired; returning nil. Caller should use getValidAccessToken() to refresh.")
      // If the token is expired, return nil. Caller should invoke getValidAccessToken() to attempt refresh asynchronously.
      return nil
    }
    return tokenStorage.getAccessToken()
  }

  public func getValidAccessToken() async throws -> String {
    if tokenStorage.getAccessToken() == nil || tokenStorage.isTokenExpired() {
      logger.debug("Access token is expired. Refreshing...")
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

    if tokenStorage.getAccessToken() != nil, !tokenStorage.isTokenExpired(), !force {
      _isAuthenticatedSubject.value = true
      scheduleRefreshTimer()
      return
    }

    if let lastFailure,
       Date().timeIntervalSince(lastFailure) < refreshCooldown {
      throw AuthUseCaseError.refreshFailed(
        NSError(domain: "AuthUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Refresh on cooldown"])
      )
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
    // Read errors (including a locked keychain) preserve the session. Only a
    // successful read confirming that the token is absent can clear it.
    guard let currentRefreshToken = try tokenStorage.readRefreshToken() else {
      endSession()
      throw AuthUseCaseError.refreshFailed(NSError(domain: "AuthUseCase", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"]))
    }

    // The server consumes a refresh token on use and hands back its successor.
    // Suspended between the two, the app would keep only the consumed token,
    // which every later refresh is rejected for.
    let activity = BackgroundActivity(reason: "Refresh access token")
    defer { activity.end() }

    do {
      // Mark the in-flight refresh on the task-local
      let tokenResponse: TokenResponse = try await AuthRetryConfig.$isRefreshing.withValue(true) {
        try await self.authenticationService.refreshAccessToken(
          refreshToken: currentRefreshToken
        )
      }
      try tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
      _isAuthenticatedSubject.value = true
      lastFailure = nil
      rejectedRefreshToken = nil
      logger.info("Successfully refreshed access token.")
      scheduleRefreshTimer() // set timer on success
      onTokenRefresh?()
    } catch {
      logger.error("Token refresh failed: \(error.localizedDescription, privacy: .public)")
      lastFailure = Date()
      // Network, decoding and 5xx errors are transient and keep the session.
      guard Self.isRefreshTokenRejected(error) else {
        throw AuthUseCaseError.refreshFailed(error)
      }
      // A widget refreshing with the same token at the same time wins the
      // rotation and leaves this request rejected, though the session is fine.
      if refreshTokenWasRotatedElsewhere(from: currentRefreshToken) {
        logger.info("Refresh token was rotated by another process; using its tokens.")
        _isAuthenticatedSubject.value = true
        lastFailure = nil
        rejectedRefreshToken = nil
        scheduleRefreshTimer()
        onTokenRefresh?()
        return
      }
      // The widget that won may not have saved its tokens yet, so the first
      // rejection keeps the session. The next refresh reads the keychain again
      // and picks up the widget's token if it arrived in the meantime.
      guard rejectedRefreshToken == currentRefreshToken else {
        logger.info("Refresh token rejected; signing out if it is rejected again.")
        rejectedRefreshToken = currentRefreshToken
        throw AuthUseCaseError.refreshFailed(error)
      }
      // Kept, a rejected token would never refresh again: every request would
      // go out with the expired access token, relaunch included, until sign-out.
      rejectedRefreshToken = nil
      endSession()
      throw AuthUseCaseError.refreshFailed(error)
    }
  }

  /// The refresh endpoint answers 400 for a malformed token and 403 for one
  /// that was already used, has expired, or belongs to a withdrawn user.
  private static func isRefreshTokenRejected(_ error: Error) -> Bool {
    switch error as? NetworkError {
    case .unauthorized: true
    case .serverError(let statusCode): statusCode == 400 || statusCode == 403
    default: false
    }
  }

  /// Whether the keychain now holds a different refresh token from the one that
  /// was rejected, saved by the winner of a cross-process race.
  private func refreshTokenWasRotatedElsewhere(from rejectedToken: String) -> Bool {
    guard let stored = try? tokenStorage.readRefreshToken() else { return false }
    return stored != rejectedToken
  }

  private func endSession() {
    tokenStorage.clearTokens()
    _isAuthenticatedSubject.value = false
    cancelRefreshTimer()
    // The session is gone, so the Credits widgets mustn't keep showing the GPA.
    clearCreditSummary()
    WidgetCenter.shared.reloadAllTimelines()
  }

  public func signIn() async throws {
    guard let araUserRepository, let feedUserRepository, let otlUserRepository else { return }
    do {
      let tokenResponse: SignInResponse = try await authenticationService.authenticate()
      try tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)

      // MARK: Sign up Ara
      let userInfo: AraSignInResponse = try await araUserRepository.register(ssoInfo: tokenResponse.ssoInfo)
      try? await araUserRepository.agreeTOS(userID: userInfo.userID)

      // MARK: Sign up Feed
      try await feedUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

      // MARK: Sign up OTL
      try await otlUserRepository.register(ssoInfo: tokenResponse.ssoInfo)

      _isAuthenticatedSubject.value = true
      logger.info("Signed in.")
      WidgetCenter.shared.reloadAllTimelines()
      scheduleRefreshTimer() // set timer on success
    } catch {
      tokenStorage.clearTokens()
      _isAuthenticatedSubject.value = false
      logger.error("Sign in failed: \(error.localizedDescription, privacy: .public)")
      cancelRefreshTimer()
      throw AuthUseCaseError.signInFailed(error)
    }
  }

  public func signOut() async throws {
    TimetableSelectionStore().clear()
    if let container = TimetableCacheContainer.shared {
      TimetableCache(modelContainer: container).clear()
    }
    tokenStorage.clearTokens()
    // After the tokens and cache, so a rebuild still running finishes first and is
    // wiped, and later ones see no session. The next account on this device must
    // not inherit this schedule in Siri or Spotlight.
    await Container.shared.timetableIndexingService()?.clear()
    // Signed out before the snapshot is cleared, so a Credits load still in flight
    // hits `publishWidgetSnapshot()`'s auth guard instead of republishing it.
    _isAuthenticatedSubject.value = false
    cancelRefreshTimer()
    // Cleared before the reload, so the Credits widgets can't show this user's GPA,
    // on the watch too.
    clearCreditSummary()
    WidgetCenter.shared.reloadAllTimelines()
    logger.info("Signed out.")
  }

  /// Removes the stored GPA snapshot, and the watch's copy, once the session ends.
  private func clearCreditSummary() {
    CreditSummarySnapshotStore().clear()
    Container.shared.sessionBridgeService()?.updateCreditSummary(nil)
  }
}
