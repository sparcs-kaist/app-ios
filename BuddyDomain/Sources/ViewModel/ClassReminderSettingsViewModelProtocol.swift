//
//  ClassReminderSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import Foundation
import Observation

/// Whether iOS will actually show what the user picked.
public enum ClassReminderAvailability: Equatable, Sendable {
  case available
  /// Live Activities are switched off for Buddy in iOS Settings; notifications are sent instead.
  case liveActivitiesOff
  /// Notifications are denied for Buddy, so nothing can be delivered.
  case notificationsDenied
}

@MainActor
public protocol ClassReminderSettingsViewModelProtocol: Observable {
  var settings: ClassReminderSettings { get set }
  var availability: ClassReminderAvailability { get }

  /// Re-reads iOS's Live Activity and notification permissions.
  func refreshAvailability() async
}
