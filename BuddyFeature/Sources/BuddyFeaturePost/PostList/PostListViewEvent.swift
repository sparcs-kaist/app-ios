//
//  PostListViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import BuddyDomain
import Foundation

enum PostListViewEvent: Event {
  case postsRefreshed
  case nextPageLoaded
  case searchPerformed(keyword: String)
  case topicSelected(topic: String?)

  var source: String { "PostListView" }

  var name: String {
    switch self {
    case .postsRefreshed:
      "posts_refreshed"
    case .nextPageLoaded:
      "next_page_loaded"
    case .searchPerformed:
      "search_performed"
    case .topicSelected:
      "topic_selected"
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .searchPerformed(let keyword):
      ["source": source, "keyword": keyword]
    case .topicSelected(let topic):
      ["source": source, "topic": topic ?? "all"]
    default:
      ["source": source]
    }
  }
}
