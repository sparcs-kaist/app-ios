import Foundation

/// A timetable slot or academic date expressed as a dated calendar event, the
/// shape Siri and Spotlight understand.
public struct ClassEvent: Hashable, Sendable, Identifiable {
  public enum Kind: Hashable, Sendable {
    case lecture(lectureID: Int)
    /// `timetableID` is nil for an activity on My Table.
    case activity(timetableID: Int?, activityID: Int)
    case academic
  }

  /// Which of the two calendars Buddy exposes an event belongs to.
  public enum CalendarKind: String, Hashable, Sendable, CaseIterable {
    case timetable
    case academic
  }

  public let id: String
  public let title: String
  public let startDate: Date
  public let endDate: Date
  public let isAllDay: Bool
  /// Weekly for a timetable series; nil for a single dated meeting or academic date.
  public let recurrence: Calendar.RecurrenceRule?
  public let location: String?
  public let note: String?
  public var kind: Kind { Self.kind(of: id) ?? .academic }
  /// Extra search terms for Spotlight and Siri, e.g. "종강" for the semester's end.
  public var keywords: [String] { ClassEventBuilder.keywords(forEventID: id) }
  public var calendar: CalendarKind { kind == .academic ? .academic : .timetable }

  public init(
    id: String,
    title: String,
    startDate: Date,
    endDate: Date,
    isAllDay: Bool = false,
    recurrence: Calendar.RecurrenceRule? = nil,
    location: String? = nil,
    note: String? = nil
  ) {
    self.id = id
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.isAllDay = isAllDay
    self.recurrence = recurrence
    self.location = location
    self.note = note
  }

  // MARK: - Identifiers
  //
  // Identifiers carry the event's kind so intents can act on an event without
  // looking it up again. Every component comes from server data, so the same
  // event has the same identifier on every device.

  public static func lectureID(_ lecture: Lecture, _ lectureClass: LectureClass) -> String {
    "lec:\(lecture.id):\(lectureClass.day.rawValue):\(lectureClass.begin)-\(lectureClass.end)"
  }

  public static func activityID(timetableID: Int?, activityID: Int) -> String {
    "act:\(timetableID.map(String.init) ?? "my"):\(activityID)"
  }

  public static func academicID(semester: Semester, field: String) -> String {
    "acad:\(semester.id):\(field)"
  }

  /// One dated meeting of a weekly series, e.g. `lec:101:0:540-630@2026-09-07`.
  public static func occurrenceID(seriesID: String, day: String) -> String {
    "\(seriesID)@\(day)"
  }

  public static func kind(of id: String) -> Kind? {
    let series = id.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
    let parts = series.split(separator: ":", omittingEmptySubsequences: false)
    switch parts.first {
    case "lec":
      guard parts.count == 4, let lectureID = Int(parts[1]) else { return nil }
      return .lecture(lectureID: lectureID)
    case "act":
      guard parts.count == 3, let activityID = Int(parts[2]) else { return nil }
      if parts[1] == "my" { return .activity(timetableID: nil, activityID: activityID) }
      guard let timetableID = Int(parts[1]) else { return nil }
      return .activity(timetableID: timetableID, activityID: activityID)
    case "acad":
      return parts.count == 3 ? .academic : nil
    default:
      return nil
    }
  }
}
