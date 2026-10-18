//
//  TimetableItemChange.swift
//  BuddyDomain
//

import Foundation

/// One change to a timetable's lectures or activities. The server applies a
/// batch of them all together or not at all, checking the finished timetable
/// for overlaps, so removing what a lecture overlaps and adding the lecture
/// never leaves the table half changed.
public enum TimetableItemChange: Hashable, Sendable {
  case addLecture(lectureID: Int)
  case removeLecture(lectureID: Int)
  case addActivity(TimetableActivityDraft)
  /// Replaces the activity's title, location and every time range.
  case updateActivity(activityID: Int, TimetableActivityDraft)
  case removeActivity(activityID: Int)
}
