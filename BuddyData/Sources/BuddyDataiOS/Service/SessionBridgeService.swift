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

  public func updateTimetable(_ timetable: Timetable) {
    guard WCSession.default.activationState == .activated else {
      print("[updateTimetable] Session not activated. Skipping update.")
      return
    }

    do {
      print("[updateTimetable] Encoding timetable with id:", timetable.id)
      let data = try JSONEncoder().encode(timetable)
      print("[updateTimetable] Encoded timetable size:", data.count, "bytes")

      try WCSession.default.updateApplicationContext([BridgeKeys.timetable: data])
      print("[updateTimetable] Successfully updated application context.")
    } catch {
      print("[updateTimetable] Failed to encode or update context:", error)
      return
    }
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
