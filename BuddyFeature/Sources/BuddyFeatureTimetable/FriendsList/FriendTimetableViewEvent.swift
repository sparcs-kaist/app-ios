//
//  FriendTimetableViewEvent.swift
//  BuddyFeature
//

import BuddyDomain
import Foundation

enum FriendTimetableViewEvent: Event {
  case timetableLoaded
  case semesterChanged
  case lectureOpened

  var source: String { "FriendTimetableView" }

  var name: String {
    switch self {
    case .timetableLoaded:
      "friend_timetable_loaded"
    case .semesterChanged:
      "friend_timetable_semester_changed"
    case .lectureOpened:
      "friend_timetable_lecture_opened"
    }
  }

  var parameters: [String: Any] {
    ["source": source]
  }
}
