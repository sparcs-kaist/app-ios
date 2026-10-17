//
//  ClassReminderSettings.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import Foundation

/// What the server is asked to do for this device.
public enum ClassReminderMode: String, Codable, CaseIterable, Sendable {
  case liveActivity = "live_activity"
  case notification
  case off
}

/// How a reminder looks, kept separately from on/off so switching reminders off and on again
/// keeps the user's choice.
public enum ClassReminderStyle: String, Codable, CaseIterable, Sendable {
  case liveActivity
  case notification
}

/// The Class Reminders settings, shared through the app group so the app, its widget extension
/// and App Intents read the same values.
public struct ClassReminderSettings: Codable, Equatable, Sendable {
  public var isEnabled: Bool
  public var style: ClassReminderStyle
  /// Minutes before a class: when the Live Activity starts, or when the notification fires.
  public var leadMinutes: Int
  public var includeCustomBlocks: Bool
  /// Shows the next class in the last 15 minutes of a class. Costs one push per class.
  public var upNext: Bool
  public var sound: Bool

  public static let leadMinuteOptions = [5, 10, 15, 30]

  public static let `default` = ClassReminderSettings(
    isEnabled: true,
    style: .liveActivity,
    leadMinutes: 15,
    includeCustomBlocks: true,
    upNext: true,
    sound: false
  )

  public init(
    isEnabled: Bool,
    style: ClassReminderStyle,
    leadMinutes: Int,
    includeCustomBlocks: Bool,
    upNext: Bool,
    sound: Bool
  ) {
    self.isEnabled = isEnabled
    self.style = style
    self.leadMinutes = leadMinutes
    self.includeCustomBlocks = includeCustomBlocks
    self.upNext = upNext
    self.sound = sound
  }

  public var mode: ClassReminderMode {
    guard isEnabled else { return .off }
    return switch style {
    case .liveActivity: .liveActivity
    case .notification: .notification
    }
  }
}

/// Reads and writes ``ClassReminderSettings`` in the app group.
public struct ClassReminderSettingsStore: Sendable {
  public static let storageKey = "classReminder.settings"
  /// Posted on the main queue after the settings change, so the service can sync them.
  public static let didChangeNotification = Notification.Name("ClassReminderSettingsDidChange")

  public init() {}

  public var settings: ClassReminderSettings {
    guard let data = TimetableThemeStore.sharedDefaults.data(forKey: Self.storageKey),
          let settings = try? JSONDecoder().decode(ClassReminderSettings.self, from: data) else {
      return .default
    }
    return settings
  }

  public func save(_ settings: ClassReminderSettings) {
    guard settings != self.settings, let data = try? JSONEncoder().encode(settings) else { return }
    TimetableThemeStore.sharedDefaults.set(data, forKey: Self.storageKey)
    NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
  }
}
