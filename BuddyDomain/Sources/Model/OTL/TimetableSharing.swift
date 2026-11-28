//
//  TimetableSharing.swift
//  BuddyDomain
//

import Foundation

/// Which of a semester's timetables the user's friends see.
public struct TimetableSharing: Equatable, Sendable {
  /// The semester's own timetables, in the user's order.
  public let timetables: [TimetableSummary]
  /// The timetable friends see, or `nil` when they see the user's enrolled lectures.
  public let sharedTimetableID: Int?

  public init(timetables: [TimetableSummary], sharedTimetableID: Int?) {
    self.timetables = timetables
    self.sharedTimetableID = sharedTimetableID
  }

  public func sharing(_ timetableID: Int?) -> TimetableSharing {
    TimetableSharing(timetables: timetables, sharedTimetableID: timetableID)
  }
}
