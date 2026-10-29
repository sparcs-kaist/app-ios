//
//  NotificationSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 29/10/2026.
//

import Foundation
import Observation

@MainActor
public protocol NotificationSettingsViewModelProtocol: Observable {
  var state: NotificationSettingsViewState { get }
  /// Whether this device gets each kind of notification, including a change still being saved.
  var preferences: [NotificationCategory: Bool] { get }
  /// Whether Buddy may show notifications at all, which is up to the system's Settings.
  var isAllowedBySystem: Bool { get }
  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

  func load() async
  func setNotifications(_ category: NotificationCategory, enabled: Bool) async
}
