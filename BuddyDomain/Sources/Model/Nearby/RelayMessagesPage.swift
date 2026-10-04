//
//  RelayMessagesPage.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// An encrypted message waiting in a nearby relay mailbox.
public struct RelayMessage: Sendable, Equatable {
  public let id: String
  public let header: Data
  public let body: Data

  public init(id: String, header: Data, body: Data) {
    self.id = id
    self.header = header
    self.body = body
  }
}

public struct RelayMessagesPage: Sendable, Equatable {
  public let messages: [RelayMessage]
  /// Pass back as `after` to acknowledge everything in this page.
  public let cursor: String

  public init(messages: [RelayMessage], cursor: String) {
    self.messages = messages
    self.cursor = cursor
  }
}
