//
//  FeedPostComposeViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import BuddyDomain
import Foundation

enum FeedPostComposeViewEvent: Event {
  case postSubmitted(isAnonymous: Bool, imageCount: Int)
  case composeTypeChanged(type: String)

  var source: String { "FeedPostComposeView" }

  var name: String {
    switch self {
    case .postSubmitted:
      "post_submitted"
    case .composeTypeChanged:
      "compose_type_changed"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .postSubmitted(let isAnonymous, let imageCount):
      ["source": source, "is_anonymous": isAnonymous, "image_count": imageCount]
    case .composeTypeChanged(let type):
      ["source": source, "compose_type": type]
    }
  }
}
