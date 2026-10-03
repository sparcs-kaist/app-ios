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
  case professorSelected

  var source: String { "CourseView" }

  var name: String {
    switch self {
    case .courseLoaded:
      "course_loaded"
    case .reviewsLoaded:
      "reviews_loaded"
    case .professorSelected:
      "professor_selected"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
