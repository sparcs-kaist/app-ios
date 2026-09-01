//
//  CourseViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/03/2026.
//

import BuddyDomain
import Foundation

enum CourseViewEvent: Event {
  case courseLoaded
  case reviewsLoaded

  var source: String { "CourseView" }

  var name: String {
    switch self {
    case .courseLoaded:
      "course_loaded"
    case .reviewsLoaded:
      "reviews_loaded"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
