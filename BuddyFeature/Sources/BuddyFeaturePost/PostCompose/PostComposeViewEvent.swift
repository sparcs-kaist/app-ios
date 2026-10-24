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
  case postEdited

  var source: String { "PostComposeView" }

  var name: String {
    switch self {
    case .postSubmitted:
      "post_submitted"
    case .postEdited:
      "post_edited"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
