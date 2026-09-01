//
//  FeedPostRowEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import BuddyDomain
import Foundation

enum FeedPostRowEvent: Event {
  case postUpvoted
  case postDownvoted
  case postReported(reason: String)

  var source: String { "FeedPostRow" }

  var name: String {
    switch self {
    case .postUpvoted:
      "post_upvoted"
    case .postDownvoted:
      "post_downvoted"
    case .postReported:
      "post_reported"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .postUpvoted:
      ["source": source]
    case .postDownvoted:
      ["source": source]
    case .postReported(let reason):
      ["source": source, "reason": reason]
    }
  }
}
