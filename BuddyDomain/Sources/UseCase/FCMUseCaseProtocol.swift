//
//  FCMUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/4/26.
//

public protocol FCMUseCaseProtocol: Sendable {
  func register(fcmToken: String) async throws
  /// Whether this device gets each kind of notification. Kinds never turned off are on.
  func notificationPreferences() async throws -> [NotificationCategory: Bool]
  /// Turns a kind of notification on or off on this device. Buddy's backend then stops or starts
  /// sending it here.
  func setNotifications(_ category: NotificationCategory, enabled: Bool) async throws
}
