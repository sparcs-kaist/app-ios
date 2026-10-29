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

  /// The values last loaded from or saved to the server, which a failed change goes back to.
  @ObservationIgnored private var savedPreferences: [NotificationCategory: Bool] = [:]
  /// The latest change to each kind, so a change that a newer one replaces isn't saved or undone.
  @ObservationIgnored private var latestChange: [NotificationCategory: Int] = [:]
  /// Changes are saved one at a time, in order, so the last one is what the server keeps.
  @ObservationIgnored private var lastSave: Task<Void, Never>?

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
      let loaded = try await fcmUseCase.notificationPreferences()
      preferences = loaded
      savedPreferences = loaded
      state = .loaded
    } catch {
      logger.error("Failed to load notification preferences: \(error.localizedDescription, privacy: .public)")
      crashlyticsService?.recordException(error: error)
      state = .error(message: error.localizedDescription)
    }
  }

  func setNotifications(_ category: NotificationCategory, enabled: Bool) async {
    // The switch moves at once, and moves back if the change can't be saved.
    preferences[category] = enabled
    let change = (latestChange[category] ?? 0) + 1
    latestChange[category] = change

    let previousSave = lastSave
    let save = Task {
      await previousSave?.value
      await self.save(category, enabled: enabled, change: change)
    }
    lastSave = save
    await save.value
  }

  private func save(_ category: NotificationCategory, enabled: Bool, change: Int) async {
    // Flipped again since: the newer change saves its own value.
    guard let fcmUseCase, latestChange[category] == change else { return }
    do {
      try await fcmUseCase.setNotifications(category, enabled: enabled)
      savedPreferences[category] = enabled
    } catch {
      logger.error("Failed to change notification preference: \(error.localizedDescription, privacy: .public)")
      guard latestChange[category] == change else { return }
      preferences[category] = savedPreferences[category]
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
