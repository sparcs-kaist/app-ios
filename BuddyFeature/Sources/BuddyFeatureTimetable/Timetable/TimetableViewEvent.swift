//
//  TimetableViewEvent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/03/2026.
//

import BuddyDomain
import Foundation

enum TimetableViewEvent: Event {
  case semesterChanged
  case timetableSelected
  case lectureAdded
  case lectureDeleted
  case tableRenamed
  case tableDeleted
  case tableCreated

  var source: String { "TimetableView" }

  var name: String {
    switch self {
    case .semesterChanged:
      "semester_changed"
    case .timetableSelected:
      "timetable_selected"
    case .lectureAdded:
      "lecture_added"
    case .lectureDeleted:
      "lecture_deleted"
    case .tableRenamed:
      "table_renamed"
    case .tableDeleted:
      "table_deleted"
    case .tableCreated:
      "table_created"
    }
  }

  var parameters: [String: Any] {
    switch self {
    default:
      ["source": source]
    }
  }
}
