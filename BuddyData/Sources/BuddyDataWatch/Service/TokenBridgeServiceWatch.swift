//
//  TokenBridgeServiceWatch.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import Combine
import WatchConnectivity
import BuddyDomain
import BuddyDataCore

public final class TokenBridgeServiceWatch: NSObject, WCSessionDelegate, TokenBridgeServiceWatchProtocol {
  private let session = WCSession.isSupported() ? WCSession.default : nil
  private let tokenStorage: TokenStorageProtocol

  // MARK: - In-memory token
  private let tokenStateSubject = CurrentValueSubject<TokenState?, Never>(nil)
  public var tokenStatePublisher: AnyPublisher<TokenState?, Never> {
    tokenStateSubject.eraseToAnyPublisher()
  }
  public var tokenState: TokenState? { tokenStateSubject.value }

  // MARK: - Refresh scheduling
  private var refreshTimer: DispatchSourceTimer?
  private static let refreshSkew: TimeInterval = 600
  private static let minDelay: TimeInterval = 10

  public init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage
    super.init()
  }

  public func start() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  // MARK: - Receiving token from iOS
  public nonisolated func session(
    _ session: WCSession,
    didReceiveUserInfo userInfo: [String: Any] = [:]
  ) {
    let kind = userInfo[BridgeKeys.kind] as? String
    guard kind == BridgeKeys.kindAuth else { return }

    let accessToken = userInfo[BridgeKeys.accessToken] as? String
    let expiresAtStr = userInfo[BridgeKeys.expiresAt] as? String

    guard
      let accessToken,
      let expiresAtStr,
      let expiresAt = expiresAtStr.toDate()
    else { return }

    let state = TokenState(accessToken: accessToken, expiresAt: expiresAt)
    tokenStorage.save(accessToken: accessToken, refreshToken: nil)
    self.scheduleRefresh(for: expiresAt)
    self.tokenStateSubject.send(state)
    #if DEBUG
    print("[TokenBridgeServiceWatch] Stored token in-memory; exp:", expiresAt)
    #endif
  }

  private func scheduleRefresh(for expiresAt: Date) {
    // Cancel previous timer if any
    refreshTimer?.cancel()
    refreshTimer = nil

    let now = Date()
    var fireInterval = expiresAt.timeIntervalSince(now) - Self.refreshSkew
    if fireInterval <= 0 {
      // Already near/over the skew window - refresh immediately
      #if DEBUG
      print("[TokenBridgeServiceWatch] Expiry near; refreshing now.")
      #endif
      requestTokenNowOrQueue()
      return
    }

    fireInterval = max(fireInterval, Self.minDelay)
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now() + fireInterval, repeating: .never)
    timer.setEventHandler { [weak self] in
      guard let self else { return }
      #if DEBUG
      print("[TokenBridgeServiceWatch] Pre-expiry refresh firing...")
      #endif
      self.requestTokenNowOrQueue()
    }
    timer.resume()
    refreshTimer = timer

    #if DEBUG
    let fireDate = Date(timeIntervalSinceNow: fireInterval)
    print("[TokenBridgeServiceWatch] Scheduled pre-expiry refresh at:", fireDate)
    #endif
  }

  private func requestTokenNowOrQueue() {
    guard let session else { return }
    let payload: [String: Any] = [BridgeKeys.request: BridgeKeys.requestAuth]

    if session.isReachable {
      session.sendMessage(payload, replyHandler: { reply in
        #if DEBUG
        print("[TokenBridgeServiceWatch] token request reply:", reply)
        #endif
      }, errorHandler: { error in
        #if DEBUG
        print("[TokenBridgeServiceWatch] sendMessage error, queuing:", error)
        #endif
        session.transferUserInfo(payload)
      })
    } else {
      session.transferUserInfo(payload)
      #if DEBUG
      print("[TokenBridgeServiceWatch] queued token request via transferUserInfo")
      #endif
    }
  }

  public func requestToken() { requestTokenNowOrQueue() }

  public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    #if DEBUG
    if let error { print("[TokenBridgeServiceWatch] activation error:", error) }
    else { print("[TokenBridgeServiceWatch] activated:", activationState.rawValue) }
    #endif

    self.requestTokenNowOrQueue()
  }

  public func sessionReachabilityDidChange(_ session: WCSession) {
    if session.isReachable, tokenStateSubject.value == nil {
      self.requestTokenNowOrQueue()
    }
  }

  #if os(iOS)
  public func sessionDidBecomeInactive(_ session: WCSession) {

  }

  public func sessionDidDeactivate(_ session: WCSession) {

  }
  #endif
  
}
