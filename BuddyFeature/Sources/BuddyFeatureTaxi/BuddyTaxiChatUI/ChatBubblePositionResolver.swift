//
//  ChatBubblePositionResolver.swift
//  BuddyFeatureTaxi
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import BuddyDomain

struct ChatBubblePositionResolver {
  func resolve(index: Int, count: Int) -> ChatBubblePosition {
    guard count > 1 else { return .single }
    if index == 0 { return .top }
    if index == count - 1 { return .bottom }
    return .middle
  }
}
