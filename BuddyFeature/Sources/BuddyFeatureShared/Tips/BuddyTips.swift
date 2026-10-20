//
//  BuddyTips.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 19/10/2026.
//

import Foundation
import TipKit
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "BuddyTips")

/// Sets up TipKit for the app and holds the debug controls for replaying tips.
public enum BuddyTips {
  /// Configures TipKit. Call once, at launch, before any tip is shown.
  public static func configure() {
    if defaults.bool(forKey: Keys.resetOnLaunch) {
      defaults.removeObject(forKey: Keys.resetOnLaunch)
      for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(onboardingKeyPrefix) {
        defaults.removeObject(forKey: key)
      }
      do {
        try Tips.resetDatastore()
      } catch {
        logger.error("Failed to reset tips: \(error.localizedDescription, privacy: .public)")
      }
    }
    do {
      try Tips.configure([.displayFrequency(showsTipsImmediately ? .immediate : .daily)])
    } catch {
      logger.error("Failed to configure tips: \(error.localizedDescription, privacy: .public)")
    }
  }

  // MARK: - Debug

  /// Forgets every tip that has been seen or acted on, so they all show again, and starts the
  /// timetable onboarding over as for a new user, even on an account that already has tables.
  ///
  /// TipKit only resets its datastore before it is configured, so this takes effect when the app
  /// next launches.
  public static func requestReset() {
    defaults.set(true, forKey: Keys.resetOnLaunch)
    defaults.set(true, forKey: Keys.replaysOnboarding)
  }

  /// Whether a reset is waiting for the next launch.
  public static var isResetPending: Bool {
    defaults.bool(forKey: Keys.resetOnLaunch)
  }

  /// Shows tips as soon as their rules allow instead of at most one new tip a day. Takes effect
  /// when the app next launches.
  public static var showsTipsImmediately: Bool {
    get { defaults.bool(forKey: Keys.showsTipsImmediately) }
    set { defaults.set(newValue, forKey: Keys.showsTipsImmediately) }
  }

  /// Whether a reset asked for the onboarding to start over as for a new user. Reading it clears
  /// it, so it applies to one run of the onboarding.
  public static func consumeOnboardingReplay() -> Bool {
    defer { defaults.removeObject(forKey: Keys.replaysOnboarding) }
    return defaults.bool(forKey: Keys.replaysOnboarding)
  }

  /// Starts the user defaults keys of the onboardings' state, which a reset clears with the tips.
  public static let onboardingKeyPrefix = "tips.onboarding."

  private static var defaults: UserDefaults { .standard }

  private enum Keys {
    static let resetOnLaunch = "tips.debug.resetOnLaunch"
    static let replaysOnboarding = "tips.debug.replaysOnboarding"
    static let showsTipsImmediately = "tips.debug.showsTipsImmediately"
  }
}
