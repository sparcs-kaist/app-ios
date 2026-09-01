//
//  FeedViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 08/02/2026.
//

import BuddyDomain
import Foundation

enum FeedViewEvent: Event {
  case feedRefreshed
  case writeFeedButtonTapped
  case openSettingsButtonTapped
  
  var source: String { "FeedView" }

  var name: String {
    switch self {
    case .feedRefreshed:
      "feed_refreshed"
    case .writeFeedButtonTapped:
      "write_feed_button_tapped"
    case .openSettingsButtonTapped:
      "open_settings_button_tapped"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
