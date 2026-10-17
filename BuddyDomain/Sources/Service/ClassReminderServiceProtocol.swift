//
//  ClassReminderServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import Foundation

/// Keeps the feed backend's copy of this device's class schedule, reminder settings and Live
/// Activity tokens current, so it can start and update the class Live Activity (or send a
/// notification) without the app running.
public protocol ClassReminderServiceProtocol: Sendable {
  /// Starts observing Live Activity tokens and authorisation. Call early at launch: a
  /// push-to-start launches the app in the background just long enough to deliver the new
  /// activity's update token.
  func start()
  /// Records this device's FCM registration token, which every push needs.
  func updateFCMToken(_ token: String)
  /// Uploads the schedule and settings if they changed since the last successful upload.
  func sync() async
  /// Forgets this device on the server, for sign-out.
  func unregister() async
}
