//
//  FeedPostViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import BuddyDomain
import Foundation

enum FeedPostViewEvent: Event {
  case commentSubmitted(isReply: Bool, isAnonymous: Bool)
  case postReported(reason: String)
  case postDeleteConfirmed
  case commentsRefreshed

  var source: String { "FeedPostView" }

  var name: String {
    switch self {
    case .commentSubmitted:
      "comment_submitted"
    case .postReported:
      "post_reported"
    case .postDeleteConfirmed:
      "post_delete_confirmed"
    case .commentsRefreshed:
      "comments_refreshed"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .commentSubmitted(let isReply, let isAnonymous):
      ["source": source, "is_reply": isReply, "is_anonymous": isAnonymous]
    case .postReported(let reason):
      ["source": source, "reason": reason]
    case .postDeleteConfirmed:
      ["source": source]
    case .commentsRefreshed:
      ["source": source]
    }
  }
}
