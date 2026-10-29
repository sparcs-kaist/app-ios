//
//  FCMRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/4/26.
//

import Foundation

public protocol FCMRepositoryProtocol: Sendable {
  func register(deviceUUID: String, fcmToken: String, deviceName: String, language: String) async throws
  func unregister(deviceUUID: String) async throws
  func fetchNotificationPreferences(deviceUUID: String) async throws -> [NotificationCategory: Bool]
  func setNotificationPreference(_ category: NotificationCategory, isEnabled: Bool, deviceUUID: String) async throws
}
