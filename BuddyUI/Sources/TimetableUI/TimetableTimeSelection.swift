import Foundation
import BuddyDomain

/// A local UI selection, not a persisted activity. Every selection belongs to one day.
public struct TimetableTimeSelection: Equatable, Sendable {
  public static let minuteStep = 15
  public static let lastMinuteOfDay = 23 * 60 + 45

  public private(set) var day: DayType
  public private(set) var begin: Int
  public private(set) var end: Int

  public init(day: DayType, begin: Int, end: Int) {
    self.day = day
    self.begin = min(max(Self.snap(begin), 0), Self.lastMinuteOfDay - Self.minuteStep)
    self.end = min(max(Self.snap(end), self.begin + Self.minuteStep), Self.lastMinuteOfDay)
  }

  public var duration: Int { end - begin }

  /// Weekend columns appear only when the form explicitly selected that day.
  var editingDays: [DayType] {
    DayType.weekdays.contains(day) ? DayType.weekdays : (DayType.weekdays + [day]).sorted()
  }

  /// Moves the entire block without changing its duration or crossing midnight.
  public func moving(to begin: Int, on day: DayType) -> Self {
    let start = min(max(Self.snap(begin), 0), Self.lastMinuteOfDay - duration)
    return Self(day: day, begin: start, end: start + duration)
  }

  public func resizingStart(to minutes: Int) -> Self {
    Self(day: day, begin: min(max(Self.snap(minutes), 0), end - Self.minuteStep), end: end)
  }

  public func resizingEnd(to minutes: Int) -> Self {
    Self(day: day, begin: begin, end: max(Self.snap(minutes), begin + Self.minuteStep))
  }

  public func overlaps(_ other: Self) -> Bool {
    day == other.day && begin < other.end && end > other.begin
  }

  public func conflictingLectures(in timetable: Timetable?) -> [Lecture] {
    timetable?.lectures.filter { lecture in
      lecture.classes.contains { time in
        time.day == day && time.end > time.begin && begin < time.end && end > time.begin
      }
    } ?? []
  }

  public func conflictingActivities(in timetable: Timetable?) -> [TimetableActivity] {
    timetable?.activities.filter { $0.day == day && $0.begin < end && begin < $0.end } ?? []
  }

  public var formattedTimeRange: String {
    "\(Self.formattedTime(begin)) – \(Self.formattedTime(end))"
  }

  public static func formattedTime(_ minutes: Int) -> String {
    let calendar = Calendar.current
    let date = calendar.date(byAdding: .minute, value: minutes, to: calendar.startOfDay(for: .now)) ?? .now
    return date.formatted(.dateTime.hour().minute())
  }

  private static func snap(_ minutes: Int) -> Int {
    Int((Double(minutes) / Double(minuteStep)).rounded()) * minuteStep
  }
}
