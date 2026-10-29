//
//  TaxiUnreadStoreProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/10/2026.
//

import Foundation

/// The number of Taxi chats you have not read yet, per room and in total, shared by every screen
/// that shows an unread badge: the Taxi tab, the Chats button and each room in the chat list.
///
/// Seeded from the server's counts, then kept current from the chat socket while the app is open:
/// a chat from someone else in a room you are not looking at adds one, and opening a room clears
/// it. The total is also the app icon's badge.
@MainActor
public protocol TaxiUnreadStoreProtocol: AnyObject, Observable {
  /// Unread chats by room ID. Rooms with none may be missing.
  var counts: [String: Int] { get }
  /// Unread chats across every room you are in, ongoing or done.
  var totalCount: Int { get }
  /// The room whose chat is on screen, whose chats are read as they arrive.
  var activeRoomID: String? { get }

  /// Replaces the counts with the server's, such as when the app comes back to the foreground.
  func refresh() async
  /// Marks `roomID` as the room on screen and clears its unread chats and notifications.
  func enterRoom(_ roomID: String)
  /// Marks `roomID` as no longer on screen, if it still is.
  func leaveRoom(_ roomID: String)
  /// Clears `roomID`'s unread chats, such as after replying to it from a notification.
  func markRead(_ roomID: String)
}
