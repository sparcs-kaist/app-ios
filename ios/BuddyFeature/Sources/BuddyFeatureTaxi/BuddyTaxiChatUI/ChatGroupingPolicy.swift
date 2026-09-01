//
//  ChatGroupingPolicy.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import BuddyDomain

protocol ChatGroupingPolicy {
  func isBubbleEligible(_ chat: TaxiChat) -> Bool
  func isSystemEvent(_ chat: TaxiChat) -> Bool
  func canGroup(_ lhs: TaxiChat, _ rhs: TaxiChat, myUserID: String?) -> Bool
}

struct TaxiGroupingPolicy: ChatGroupingPolicy {
  let maxGap: TimeInterval = 60 // 1 min

  func isBubbleEligible(_ chat: TaxiChat) -> Bool {
    switch chat.type {
    case .text, .s3img:
      return true
    default:
      return false
    }
  }

  func isSystemEvent(_ chat: TaxiChat) -> Bool {
    switch chat.type {
    case .entrance, .exit, .departure, .arrival, .settlement, .share:
      return true
    default:
      return false
    }
  }

  func canGroup(_ lhs: TaxiChat, _ rhs: TaxiChat, myUserID: String?) -> Bool {
    guard isBubbleEligible(lhs), isBubbleEligible(rhs) else { return false }
    guard lhs.authorID == rhs.authorID else { return false }

    // keep mine/theirs split explicit
    let lhsIsMine = lhs.authorID == myUserID
    let rhsIsMine = rhs.authorID == myUserID
    guard lhsIsMine == rhsIsMine else { return false }

    let gap = rhs.time.timeIntervalSince(lhs.time)
    return gap >= 0 && gap <= maxGap
  }
}
