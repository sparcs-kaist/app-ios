import Foundation

/// Independently cached resources for restoring the timetable screen before refreshing.
public struct TimetableCachedState: Sendable {
  public var semesters: [Semester]?
  public var currentSemester: Semester?
  public var timetables: [TimetableSummary]?
  public var timetable: Timetable?
  public var updatedAt: Date?

  public init(semesters: [Semester]? = nil, currentSemester: Semester? = nil,
              timetables: [TimetableSummary]? = nil, timetable: Timetable? = nil, updatedAt: Date? = nil) {
    self.semesters = semesters
    self.currentSemester = currentSemester
    self.timetables = timetables
    self.timetable = timetable
    self.updatedAt = updatedAt
  }
}
