//
//  ChatRenderItem.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation

public enum ChatRenderItem: Hashable, Identifiable {
  case daySeparator(Date)
  case systemEvent(
    id: UUID,
    chat: TaxiChat
  )
  case message(
    id: UUID,
    chat: TaxiChat,
    kind: TaxiChat.ChatType,
    sender: SenderInfo,
    position: ChatBubblePosition,
    metadata: MetadataVisibility
  )

  public var id: AnyHashable {
    switch self {
    case .daySeparator(let date):
      return AnyHashable("day-\(date.timeIntervalSince1970)")
    case .systemEvent(let id, _):
      return AnyHashable("system-\(id)")
    case .message(let id, _, _, _, _, _):
      return AnyHashable("message-\(id)")
    }
  }
}