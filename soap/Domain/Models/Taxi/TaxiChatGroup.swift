//
//  TaxiChatGroup.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

struct TaxiChatGroup: Identifiable, Hashable, Sendable {
  let id: String
  var chats: [TaxiChat]
  let lastChatID: UUID?
  let authorID: String?
  let authorName: String?
  let authorProfileURL: URL?
  let authorIsWithdrew: Bool?
  let time: Date        // to display time
  let isMe: Bool        // if sender of chats is me
  let isGeneral: Bool   // if TaxiChat.ChatType is .entrance or .exit. Does not show user wrapper in this case.
}
