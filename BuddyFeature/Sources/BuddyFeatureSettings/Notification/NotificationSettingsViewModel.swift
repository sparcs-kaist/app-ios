//
//  NotificationSettingsViewModel.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/6/26.
//

import Foundation
import Factory
import BuddyDomain
import UserNotifications
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "NotificationSettingsViewModel")

@MainActor
@Observable
final class NotificationSettingsViewModel: NotificationSettingsViewModelProtocol {
  // MARK: - Properties
  var state: NotificationSettingsViewState = .loading
  var preferences: [NotificationCategory: Bool] = [:]
  var isAllowedBySystem: Bool = true
  var alertState: AlertState?
  var isAlertPresented: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.fcmUseCase) private var fcmUseCase: FCMUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?

  // MARK: - Functions
  func load() async {
    isAllowedBySystem = await Self.isAllowedBySystem()
    guard let fcmUseCase else { return }

    // Coming back from the system's Settings should not flash a spinner over switches already shown.
    if preferences.isEmpty {
      state = .loading
    }
    do {
      preferences = try await fcmUseCase.notificationPreferences()
      state = .loaded
    } catch {
      logger.error("Failed to load notification preferences: \(error.localizedDescription, privacy: .public)")
      crashlyticsService?.recordException(error: error)
      state = .error(message: error.localizedDescription)
    }
  }

  func setNotifications(_ category: NotificationCategory, enabled: Bool) async {
    guard let fcmUseCase else { return }

    // The switch moves at once, and moves back if the change can't be saved.
    let previous = preferences[category]
    preferences[category] = enabled
    do {
      try await fcmUseCase.setNotifications(category, enabled: enabled)
    } catch {
      logger.error("Failed to change notification preference: \(error.localizedDescription, privacy: .public)")
      preferences[category] = previous
      alertState = .init(
        title: String(localized: "Couldn’t Change Notifications", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  private nonisolated static func isAllowedBySystem() async -> Bool {
    await UNUserNotificationCenter.current().notificationSettings().authorizationStatus != .denied
  }
}
