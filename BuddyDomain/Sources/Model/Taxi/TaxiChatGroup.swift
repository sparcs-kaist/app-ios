//
//  TaxiChatGroup.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

public struct TaxiChatGroup: Identifiable, Hashable, Sendable {
  public let id: String
  public var chats: [TaxiChat]
  public let lastChatID: UUID?
  public let authorID: String?
  public let authorName: String?
  public let authorProfileURL: URL?
  public let authorIsWithdrew: Bool?
  public let time: Date        // to display time
  public let isMe: Bool        // if sender of chats is me
  public let isGeneral: Bool   // if TaxiChat.ChatType is .entrance or .exit. Does not show user wrapper in this case.

  public init(
    id: String,
    chats: [TaxiChat],
    lastChatID: UUID?,
    authorID: String?,
    authorName: String?,
    authorProfileURL: URL?,
    authorIsWithdrew: Bool?,
    time: Date,
    isMe: Bool,
    isGeneral: Bool
  ) {
    self.id = id
    self.chats = chats
    self.lastChatID = lastChatID
    self.authorID = authorID
    self.authorName = authorName
    self.authorProfileURL = authorProfileURL
    self.authorIsWithdrew = authorIsWithdrew
    self.time = time
    self.isMe = isMe
    self.isGeneral = isGeneral
  }
}
