//
//  SessionBridgeService.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import os
import WatchConnectivity
import BuddyDomain

private let logger = Logger(subsystem: "org.sparcs.soap", category: "WatchSession")

public final class SessionBridgeService: NSObject, WCSessionDelegate, SessionBridgeServiceProtocol {
  private let session = WCSession.isSupported() ? WCSession.default : nil
  /// Updates sent before activation completes, flushed once it does — otherwise a
  /// sign-out right after launch would never clear the watch's credit totals.
  private let pendingUpdates = OSAllocatedUnfairLock(initialState: [String: Data]())

  public override init() {
    super.init()
  }

  public func start() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  public func updateTimetable(_ timetable: Timetable) {
    do {
      logger.debug("updateTimetable: encoding timetable with id \(timetable.id, privacy: .public)")
      let data = try JSONEncoder().encode(timetable)
      logger.debug("updateTimetable: encoded timetable size \(data.count) bytes")

      // Carries the theme along too, so a refresh keeps the watch in step even
      // if a theme change couldn't be delivered at the time it was made.
      send([BridgeKeys.timetable: data], includingSelectedTheme: true)
    } catch {
      logger.error("updateTimetable: failed to encode or update context: \(error.localizedDescription, privacy: .public)")
      return
    }
  }

  public func updateSelectedTheme() {
    send([:], includingSelectedTheme: true)
  }

  public func updateCreditSummary(_ snapshot: CreditSummarySnapshot?) {
    // Empty data rather than a missing key: the context is merged, so a removed
    // key would leave the previous user's totals on the watch.
    let data = snapshot.flatMap { try? JSONEncoder().encode($0) } ?? Data()
    send([BridgeKeys.creditSummary: data], includingSelectedTheme: false)
  }

  /// `updateApplicationContext` replaces the whole context, so merge into what
  /// was last sent — `session.applicationContext` survives relaunches, which
  /// keeps a theme-only push from wiping the timetable the watch already has.
  private func send(_ updates: [String: Data], includingSelectedTheme: Bool) {
    guard let session else { return }

    // Checked and queued under the lock the activation callback drains with, so
    // an update can't slip in between the drain and activation.
    // Unchecked: the closure reads the non-Sendable session, synchronously.
    let isQueued = pendingUpdates.withLockUnchecked { pending in
      guard session.activationState != .activated else { return false }
      pending.merge(updates) { _, new in new }
      return true
    }
    if isQueued {
      // The theme is always sent on activation, so it needs no queueing.
      logger.debug("send: session not activated. Queued update for activation.")
      return
    }

    var context = session.applicationContext
    context.merge(updates) { _, new in new }

    if includingSelectedTheme {
      let theme = TimetableThemeStore().selectedTheme
      if let data = try? JSONEncoder().encode(theme) {
        context[BridgeKeys.timetableTheme] = data
        logger.debug("send: including theme \(theme.id, privacy: .public)")
      } else {
        logger.error("send: failed to encode theme \(theme.id, privacy: .public)")
      }
    }

    do {
      try session.updateApplicationContext(context)
      logger.debug("send: successfully updated application context.")
    } catch {
      logger.error("send: failed to update context: \(error.localizedDescription, privacy: .public)")
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

    // Activation is async, so this is the first point a push can land. Catches up
    // the watch on any theme change made while it was unreachable, and on the
    // updates queued before activation.
    guard activationState == .activated else { return }
    let queued = pendingUpdates.withLock { pending in
      defer { pending = [:] }
      return pending
    }
    send(queued, includingSelectedTheme: true)
  }

  public func sessionDidBecomeInactive(_ session: WCSession) {
    logger.debug("sessionDidBecomeInactive")
  }

  public func sessionDidDeactivate(_ session: WCSession) {
    logger.debug("sessionDidDeactivate")
  }
}
