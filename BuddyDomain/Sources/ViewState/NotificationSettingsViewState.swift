//
//  NotificationSettingsViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 29/10/2026.
//

import Foundation

public enum NotificationSettingsViewState: Equatable {
  case loading
  case loaded
  case error(message: String)
}
