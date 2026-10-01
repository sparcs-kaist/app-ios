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
import WidgetKit
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
    // Each key is handled on its own: the phone can push a theme change without
    // a timetable, and one failing to decode mustn't discard the other.
    if let data = applicationContext[BridgeKeys.timetable] as? Data {
      receiveTimetable(data)
    }
    if let data = applicationContext[BridgeKeys.timetableTheme] as? Data {
      receiveTheme(data)
    }
    if let data = applicationContext[BridgeKeys.creditSummary] as? Data {
      receiveCreditSummary(data)
    }
  }

  /// Stores the phone's Credits totals for the watch's Credits widget. Empty data
  /// means the phone signed out (or never computed them), so clear them.
  private func receiveCreditSummary(_ data: Data) {
    let store = CreditSummarySnapshotStore()
    if let snapshot = try? JSONDecoder().decode(CreditSummarySnapshot.self, from: data) {
      store.save(snapshot)
    } else {
      store.clear()
    }
    WidgetCenter.shared.reloadTimelines(ofKind: CreditSummarySnapshotStore.widgetKind)
  }

  private func receiveTimetable(_ data: Data) {
    do {
      _ = try JSONDecoder().decode(Timetable.self, from: data)  // test if timetable is valid
      UserDefaults(suiteName: "group.org.sparcs.soap")!.set(data, forKey: "timetableData")
    } catch {
      logger.error("Failed to decode timetable: \(error.localizedDescription, privacy: .public)")
      UserDefaults(suiteName: "group.org.sparcs.soap")!.set(nil, forKey: "timetableData")
    }
    // The Smart Stack widget renders this data; a new table (or a cleared one)
    // changes what it should show right now.
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Stores the phone's choice so `TimetableTheme.current` resolves to it here
  /// exactly as it does on iOS. A user's own theme has to be saved locally first,
  /// since only the provided ones exist on both sides; `save` ignores those.
  private func receiveTheme(_ data: Data) {
    do {
      let theme = try JSONDecoder().decode(TimetableTheme.self, from: data)
      let store = TimetableThemeStore()
      store.save(theme)
      store.select(id: theme.id)
      logger.debug("Applied theme \(theme.id, privacy: .public) from iOS")
      // Widgets colour their entries with this theme.
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      logger.error("Failed to decode theme: \(error.localizedDescription, privacy: .public)")
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
