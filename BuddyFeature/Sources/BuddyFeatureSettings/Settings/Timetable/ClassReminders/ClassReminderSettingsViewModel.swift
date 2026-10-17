//
//  ClassReminderSettingsViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import ActivityKit
import Foundation
import UserNotifications
import BuddyDomain

@MainActor
@Observable
final class ClassReminderSettingsViewModel: ClassReminderSettingsViewModelProtocol {
  // MARK: - Properties
  var settings: ClassReminderSettings {
    didSet {
      guard settings != oldValue else { return }
      store.save(settings)
      if settings.isEnabled, settings.style == .notification || settings.sound {
        Task { await requestNotificationPermission() }
      }
      Task { await refreshAvailability() }
    }
  }
  var availability: ClassReminderAvailability = .available

  @ObservationIgnored private let store: ClassReminderSettingsStore

  init(store: ClassReminderSettingsStore = ClassReminderSettingsStore()) {
    self.store = store
    self.settings = store.settings
  }

  // MARK: - Functions
  func refreshAvailability() async {
    let notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    if settings.style == .liveActivity, !ActivityAuthorizationInfo().areActivitiesEnabled {
      // The server falls back to notifications, so those must be allowed for anything to arrive.
      availability = notificationStatus == .denied ? .notificationsDenied : .liveActivitiesOff
    } else if settings.style == .notification, notificationStatus == .denied {
      availability = .notificationsDenied
    } else {
      availability = .available
    }
  }

  private func requestNotificationPermission() async {
    let center = UNUserNotificationCenter.current()
    guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
    _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    await refreshAvailability()
  }
}
