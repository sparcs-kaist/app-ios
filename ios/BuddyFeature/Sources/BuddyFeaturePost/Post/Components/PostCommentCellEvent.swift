//
//  PostCommentCellEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import BuddyDomain
import Foundation

enum PostCommentCellEvent: Event {
  case commentUpvoted
  case commentDownvoted
  case commentReported(type: String)
  case commentDeleted

  var source: String { "PostCommentCell" }

  var name: String {
    switch self {
    case .commentUpvoted:
      "comment_upvoted"
    case .commentDownvoted:
      "comment_downvoted"
    case .commentReported:
      "comment_reported"
    case .commentDeleted:
      "comment_deleted"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .commentReported(let type):
      ["source": source, "type": type]
    default:
      ["source": source]
    }
  }
}
