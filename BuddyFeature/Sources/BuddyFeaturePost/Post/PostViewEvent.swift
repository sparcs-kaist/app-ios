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
  case summaryRequested
  case summaryFinished
  case summaryFailed(reason: SummarisationError)
  case translationRequested(target: String)
  case authorBlockToggled(isBlocked: Bool)

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
    case .summaryRequested:
      "summarise_requested"
    case .summaryFinished:
      "post_summary_finished"
    case .summaryFailed:
      "post_summary_failed"
    case .translationRequested:
      "translation_requested"
    case .authorBlockToggled:
      "author_block_toggled"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .bookmarkToggled(let isBookmarked):
      ["source": source, "isBookmarked": "\(isBookmarked)"]
    case .authorBlockToggled(let isBlocked):
      ["source": source, "isBlocked": "\(isBlocked)"]
    case .postReported(let type):
      ["source": source, "type": type]
    case .translationRequested(let target):
      ["source": source, "target": target]
    case .summaryFailed(let reason):
      ["source": source, "reason": String(describing: reason)]
    default:
      ["source": source]
    }
  }
}
