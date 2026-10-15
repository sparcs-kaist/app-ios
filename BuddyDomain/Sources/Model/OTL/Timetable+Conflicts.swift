//
//  Timetable+Conflicts.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 01/10/2026.
//

import Foundation

public extension Timetable {
  /// Whether the timetable already holds this lecture.
  func contains(_ lecture: Lecture) -> Bool {
    lectures.contains { $0.id == lecture.id }
  }

  /// The lectures and activities whose times overlap `lecture`. The lecture itself never counts,
  /// so an added lecture has no conflicts with itself.
  func overlapping(with lecture: Lecture) -> (lectures: [Lecture], activities: [TimetableActivity]) {
    func overlapsLecture(day: DayType, begin: Int, end: Int) -> Bool {
      lecture.classes.contains { $0.day == day && $0.begin < end && begin < $0.end }
    }
    let overlappingLectures = lectures.filter { other in
      other.id != lecture.id && other.classes.contains { overlapsLecture(day: $0.day, begin: $0.begin, end: $0.end) }
    }
    let overlappingActivities = activities.filter { overlapsLecture(day: $0.day, begin: $0.begin, end: $0.end) }
    return (overlappingLectures, overlappingActivities)
  }

  /// The names of the lectures and activities whose times overlap `lecture`, lectures first.
  func conflicts(with lecture: Lecture) -> [String] {
    let overlapping = overlapping(with: lecture)
    return overlapping.lectures.map(\.name) + overlapping.activities.map(\.title)
  }
}
