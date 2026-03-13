//
//  LectureSearchViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/03/2026.
//

import BuddyDomain
import Foundation

enum LectureSearchViewEvent: Event {
  case lecturesSearched

  var source: String { "LectureSearchView" }

  var name: String {
    switch self {
    case .lecturesSearched:
      "lectures_searched"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
