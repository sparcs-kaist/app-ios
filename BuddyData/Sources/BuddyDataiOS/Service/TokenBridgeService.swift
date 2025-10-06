//
//  TokenBridgeService.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import Combine
import WatchConnectivity
import BuddyDomain

public protocol AuthRefresher: Sendable {
  func refreshAccessToken(force: Bool) async throws
}

public struct MainActorAuthRefresher: AuthRefresher {
  private let inner: AuthUseCaseProtocol
  public init(inner: AuthUseCaseProtocol) {
    self.inner = inner
  }

  public func refreshAccessToken(force: Bool) async throws {
    try await inner.refreshAccessToken(force: force)
  }
}

public final class TokenBridgeService: NSObject, WCSessionDelegate, TokenBridgeServiceProtocol {
  private let session = WCSession.isSupported() ? WCSession.default : nil
  private let tokenStorage: TokenStorageProtocol
  private let refresher: AuthRefresher

  private var cancellables = Set<AnyCancellable>()

  public init(
    tokenStorage: TokenStorageProtocol,
    authUseCase: AuthUseCaseProtocol
  ) {
    self.tokenStorage = tokenStorage
    self.refresher = MainActorAuthRefresher(inner: authUseCase)
    super.init()
  }

  public func start() {
    guard let session else { return }
    session.delegate = self
    session.activate()

    if let state = tokenStorage.currentTokenState { push(state) }

    tokenStorage.tokenStatePublisher
      .removeDuplicates()
      .compactMap { $0 }
      .sink { [weak self] state in
        guard let self else { return }
        // already on @MainActor because the class is @MainActor
        self.push(state)
      }
      .store(in: &cancellables)
  }

  private func push(_ state: TokenState) {
    guard let session,
          session.isPaired,
          session.isWatchAppInstalled else {
      #if DEBUG
      print("[TokenBridgeService] push aborted – session not ready. Paired:", session?.isPaired ?? false, "Installed:", session?.isWatchAppInstalled ?? false)
      #endif
      return
    }

    let payload: [String: Any] = [
      BridgeKeys.kind: BridgeKeys.kindAuth,
      BridgeKeys.accessToken: state.accessToken,
      BridgeKeys.expiresAt: state.expiresAt.toISO8601
    ]

    #if DEBUG
    print("[TokenBridgeService] pushing token → expiresAt:", state.expiresAt, "payload:", payload)
    #endif

    session.transferUserInfo(payload)

    #if DEBUG
    print("[TokenBridgeService] transferUserInfo queued successfully")
    #endif
  }

  // MARK: - WCSessionDelegate (nonisolated shims)

  public func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    // Read on the delegate's thread; don't capture `message` later.
    let isAuthRequest = (message[BridgeKeys.request] as? String) == BridgeKeys.requestAuth

    // Reply quickly on the current callback queue.
    replyHandler(["status": "accepted"])

    // Hop to the main actor with only Sendable data.
    guard isAuthRequest else { return }
    let refresher = self.refresher
    Task { [refresher] in
      try? await refresher.refreshAccessToken(force: true)
    }
  }

  public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    Task { @MainActor in
      #if DEBUG
      if let error { print("[TokenBridgeService] activation error:", error) }
      else { print("[TokenBridgeService] activated:", activationState.rawValue) }
      #endif
    }
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {
    Task { @MainActor in
      #if DEBUG
      print("[TokenBridgeService] sessionDidBecomeInactive")
      #endif
    }
  }

  public func sessionDidDeactivate(_ session: WCSession) {
    Task { @MainActor in
      #if DEBUG
      print("[TokenBridgeService] sessionDidDeactivate")
      #endif
    }
  }
}
