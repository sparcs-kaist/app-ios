//
//  PostViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import BuddyDomain
import Foundation

enum PostViewEvent: Event {
  case postUpvoted
  case postDownvoted
  case bookmarkToggled(isBookmarked: Bool)
  case commentSubmitted
  case postReported(type: String)
  case postDeleted
  case summariseRequested

  var source: String { "PostView" }

  var name: String {
    switch self {
    case .postUpvoted:
      "post_upvoted"
    case .postDownvoted:
      "post_downvoted"
    case .bookmarkToggled:
      "bookmark_toggled"
    case .commentSubmitted:
      "comment_submitted"
    case .postReported:
      "post_reported"
    case .postDeleted:
      "post_deleted"
    case .summariseRequested:
      "summarise_requested"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .bookmarkToggled(let isBookmarked):
      ["source": source, "isBookmarked": "\(isBookmarked)"]
    case .postReported(let type):
      ["source": source, "type": type]
    default:
      ["source": source]
    }
  }
}
