//
//  TaxiQuickReplyUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/10/2026.
//

import Foundation

/// Replies to a Taxi chat from its notification, without opening the app.
public protocol TaxiQuickReplyUseCaseProtocol: Sendable {
  /// Sends `text` to `roomID` and marks the room read, since you have just replied to it.
  func reply(_ text: String, roomID: String) async throws
}
