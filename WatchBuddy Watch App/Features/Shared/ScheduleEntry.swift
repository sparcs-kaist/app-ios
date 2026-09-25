//
//  ScheduleEntry.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain

/// One item on a day's schedule: an academic lecture or a custom activity,
/// unified so the watch views can page, list, and lay out both alike.
enum ScheduleEntry: Identifiable, Hashable {
  case lecture(LectureItem)
  case activity(TimetableActivity)

  var id: String {
    switch self {
    case .lecture(let item): item.id
    case .activity(let activity): "activity-\(activity.id)-\(activity.day)-\(activity.begin)"
    }
  }

  var title: String {
    switch self {
    case .lecture(let item): item.lecture.name
    case .activity(let activity): activity.title
    }
  }

  var location: String {
    switch self {
    case .lecture(let item): item.lectureClass.location
    case .activity(let activity): activity.location
    }
  }

  /// Time-of-day details in one shape for both kinds. An activity borrows
  /// `LectureClass` so it reuses its formatting and status strings.
  var classTime: LectureClass {
    switch self {
    case .lecture(let item):
      item.lectureClass
    case .activity(let activity):
      LectureClass(
        day: activity.day,
        begin: activity.begin,
        end: activity.end,
        buildingCode: "",
        buildingName: "",
        roomName: activity.location
      )
    }
  }

  /// Colour in the theme selected in Settings (`TimetableTheme.current`).
  var backgroundColor: Color {
    switch self {
    case .lecture(let item): item.lecture.backgroundColor
    case .activity(let activity): activity.backgroundColor
    }
  }

  /// Colour in an explicit theme, for views inside a themed hierarchy.
  func color(in theme: TimetableTheme) -> Color {
    switch self {
    case .lecture(let item): theme.color(forCourseID: item.lecture.courseID)
    case .activity(let activity): theme.color(forActivityID: activity.id)
    }
  }
}

extension Timetable {
  /// Lectures and activities for one day, in chronological order.
  func scheduleEntries(day: DayType) -> [ScheduleEntry] {
    let lectures = getLectures(day: day)
      .filter { $0.lectureClass.duration > 0 }
      .map(ScheduleEntry.lecture)
    let dayActivities = activities
      .filter { $0.day == day && $0.duration > 0 }
      .map(ScheduleEntry.activity)
    return (lectures + dayActivities).sorted { $0.classTime.begin < $1.classTime.begin }
  }
}
