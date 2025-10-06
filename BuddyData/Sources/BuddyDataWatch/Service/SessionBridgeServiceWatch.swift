//
//  SessionBridgeServiceWatch.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import Combine
import WatchConnectivity
import BuddyDomain
import BuddyDataCore

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
      UserDefaults.standard.set(data, forKey: "timetableData")
    } catch {
      print("Failed to decode:", error)
      UserDefaults.standard.set(nil, forKey: "timetableData")
      return
    }
  }

  public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
  ) {
    #if DEBUG
    if let error { print("[SessionBridgeServiceWatch] activation error:", error) }
    else { print("[SessionBridgeServiceWatch] activated:", activationState.rawValue) }
    #endif
  }

  #if os(iOS)
  public func sessionDidBecomeInactive(_ session: WCSession) {

  }

  public func sessionDidDeactivate(_ session: WCSession) {

  }
  #endif
  
}
