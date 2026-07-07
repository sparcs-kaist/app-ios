//
//  SessionBridgeServiceWatch.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import os
import Combine
import WatchConnectivity
import BuddyDomain
import BuddyDataCore

private let logger = Logger(subsystem: "org.sparcs.soap", category: "WatchSession")

public final class SessionBridgeServiceWatch: NSObject, WCSessionDelegate, SessionBridgeServiceWatchProtocol {
  private let session = WCSession.isSupported() ? WCSession.default : nil

  public func start() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  // MARK: - Receiving token from iOS
  public func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    guard let data = applicationContext[BridgeKeys.timetable] as? Data else { return }
    do {
      _ = try JSONDecoder().decode(Timetable.self, from: data)  // test if timetable is valid
      UserDefaults(suiteName: "group.org.sparcs.soap")!.set(data, forKey: "timetableData")
    } catch {
      logger.error("Failed to decode timetable: \(error.localizedDescription, privacy: .public)")
      UserDefaults(suiteName: "group.org.sparcs.soap")!.set(nil, forKey: "timetableData")
      return
    }
  }

  public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    if let error { logger.error("Activation error: \(error.localizedDescription, privacy: .public)") }
    else { logger.debug("Activated: \(activationState.rawValue)") }
  }

  #if os(iOS)
  public func sessionDidBecomeInactive(_ session: WCSession) {

  }

  public func sessionDidDeactivate(_ session: WCSession) {

  }
  #endif
  
}
