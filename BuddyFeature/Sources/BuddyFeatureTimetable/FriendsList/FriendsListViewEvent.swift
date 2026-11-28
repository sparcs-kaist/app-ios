//
//  FriendsListViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import BuddyDomain
import Foundation

enum FriendsListViewEvent: Event {
  case friendsLoaded
  case friendAdded
  case friendDeleted
  case favoriteToggled
  case sharedTimetableChanged

  var source: String { "FriendsListView" }

  var name: String {
    switch self {
    case .friendsLoaded:
      "friends_loaded"
    case .friendAdded:
      "friend_added"
    case .friendDeleted:
      "friend_deleted"
    case .favoriteToggled:
      "friend_favorite_toggled"
    case .sharedTimetableChanged:
      "friend_shared_timetable_changed"
    }
  }

  var parameters: [String: Any] {
    ["source": source]
  }
}
