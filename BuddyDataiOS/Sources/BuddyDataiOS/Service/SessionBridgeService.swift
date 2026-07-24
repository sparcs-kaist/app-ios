//
//  SessionBridgeService.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import BuddyDomain

// WatchConnectivity is iOS/watchOS only, so the whole bridge compiles out on macOS.
// Container registers `nil` for `sessionBridgeService` there instead.
#if os(iOS)
import os
import WatchConnectivity

private let logger = Logger(subsystem: "org.sparcs.soap", category: "WatchSession")

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
      logger.debug("updateTimetable: session not activated. Skipping update.")
      return
    }

    do {
      logger.debug("updateTimetable: encoding timetable with id \(timetable.id, privacy: .public)")
      let data = try JSONEncoder().encode(timetable)
      logger.debug("updateTimetable: encoded timetable size \(data.count) bytes")

      try WCSession.default.updateApplicationContext([BridgeKeys.timetable: data])
      logger.debug("updateTimetable: successfully updated application context.")
    } catch {
      logger.error("updateTimetable: failed to encode or update context: \(error.localizedDescription, privacy: .public)")
      return
    }
  }

  // MARK: - WCSessionDelegate

  public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    if let error { logger.error("Activation error: \(error.localizedDescription, privacy: .public)") }
    else { logger.debug("Activated: \(activationState.rawValue)") }
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {
    logger.debug("sessionDidBecomeInactive")
  }

  public func sessionDidDeactivate(_ session: WCSession) {
    logger.debug("sessionDidDeactivate")
  }
}
#endif
