//
//  AddFriendsViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import BuddyDomain
import Foundation

enum AddFriendsViewEvent: Event {
  case nearbyStarted
  case requestSent
  case requestAccepted
  case requestDeclined
  case friendAdded

  var source: String { "AddFriendsView" }

  var name: String {
    switch self {
    case .nearbyStarted:
      "nearby_friends_started"
    case .requestSent:
      "nearby_friend_request_sent"
    case .requestAccepted:
      "nearby_friend_request_accepted"
    case .requestDeclined:
      "nearby_friend_request_declined"
    case .friendAdded:
      "nearby_friend_added"
    }
  }

  var parameters: [String: Any] {
    ["source": source]
  }
}
