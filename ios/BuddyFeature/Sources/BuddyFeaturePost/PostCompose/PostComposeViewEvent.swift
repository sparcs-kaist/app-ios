//
//  PostComposeViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import BuddyDomain
import Foundation

enum PostComposeViewEvent: Event {
  case postSubmitted

  var source: String { "PostComposeView" }

  var name: String {
    switch self {
    case .postSubmitted:
      "post_submitted"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
