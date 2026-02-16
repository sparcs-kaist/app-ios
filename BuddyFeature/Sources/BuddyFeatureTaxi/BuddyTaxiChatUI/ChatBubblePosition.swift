//
//  ChatBubblePosition.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

enum ChatBubblePosition: Hashable {
  case single
  case top
  case middle
  case bottom
}

struct ChatBubblePositionResolver {
  func resolve(index: Int, count: Int) -> ChatBubblePosition {
    guard count > 1 else { return .single }
    if index == 0 { return .top }
    if index == count - 1 { return .bottom }
    return .middle
  }
}
