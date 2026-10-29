//
//  PreviewNotificationSettingsViewModel.swift
//  BuddyPreviewSupport
//
//  Created by Soongyu Kwon on 29/10/2026.
//

import Foundation
import BuddyDomain

@Observable
public final class PreviewNotificationSettingsViewModel: NotificationSettingsViewModelProtocol {
  public var state: NotificationSettingsViewState = .loaded
  public var preferences: [NotificationCategory: Bool] = [.taxiEvent: false]
  public var isAllowedBySystem: Bool = true
  public var alertState: AlertState?
  public var isAlertPresented: Bool = false

  public init() { }

  public func load() async { }

  public func refreshSystemPermission() async { }

  public func setNotifications(_ category: NotificationCategory, enabled: Bool) async {
    preferences[category] = enabled
  }
}
