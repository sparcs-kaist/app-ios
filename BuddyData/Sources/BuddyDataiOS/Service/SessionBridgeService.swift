//
//  SessionBridgeService.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import WatchConnectivity
import BuddyDomain

public final class SessionBridgeService: NSObject, WCSessionDelegate, SessionBridgeServiceProtocol {
  private let session = WCSession.isSupported() ? WCSession.default : nil

  public override init() {
    super.init()
  }

  public func start() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  public func updateAppContext(_ context: [String: Any]) {
    guard WCSession.default.activationState == .activated else {
      return
    }

    try? WCSession.default.updateApplicationContext(context)
  }

  // MARK: - WCSessionDelegate

  public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    #if DEBUG
    if let error { print("[SessionBridgeService] activation error:", error) }
    else { print("[SessionBridgeService] activated:", activationState.rawValue) }
    #endif
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {
    #if DEBUG
    print("[SessionBridgeService] sessionDidBecomeInactive")
    #endif
  }

  public func sessionDidDeactivate(_ session: WCSession) {
    #if DEBUG
    print("[SessionBridgeService] sessionDidDeactivate")
    #endif
  }
}
