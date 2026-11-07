//
//  NotificationCategory.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 29/10/2026.
//

import Foundation

/// A kind of notification you can turn on or off on each device. The raw values are the
/// categories Buddy's backend knows them by.
public enum NotificationCategory: String, CaseIterable, Sendable {
  /// Comments on your Feed posts.
  case feedComment = "feed_comment"
  /// Replies to your Feed comments.
  case feedReply = "feed_reply"
  /// Chats in your Taxi rides.
  case taxiChat = "taxi_chat"
  /// Updates on your Taxi rides, such as riders joining, settlement and departure reminders.
  case taxiEvent = "taxi_event"
  case ara
  case timetable
}
