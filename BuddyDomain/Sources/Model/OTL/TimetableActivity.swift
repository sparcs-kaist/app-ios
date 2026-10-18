import Foundation
import SwiftUI

/// One weekly time range of a custom timetable block.
public struct TimetableActivityTime: Hashable, Codable, Sendable {
  public var day: DayType
  public var begin: Int
  public var end: Int

  public init(day: DayType, begin: Int, end: Int) {
    self.day = day
    self.begin = begin
    self.end = end
  }

  public var duration: Int { end - begin }

  public var isValid: Bool { begin >= 0 && end <= 1440 && begin < end }

  public func overlaps(day: DayType, begin: Int, end: Int) -> Bool {
    self.day == day && self.begin < end && begin < self.end
  }

  public func overlaps(_ other: Self) -> Bool {
    overlaps(day: other.day, begin: other.begin, end: other.end)
  }
}

/// A custom timetable block, separate from academic lectures and their credits.
/// Like a lecture's classes, one block can meet at several weekly times.
public struct TimetableActivity: Identifiable, Hashable, Codable, Sendable {
  public let id: Int
  public var title: String
  public var location: String
  public var times: [TimetableActivityTime]

  public init(id: Int, title: String, location: String, times: [TimetableActivityTime]) {
    self.id = id
    self.title = title
    self.location = location
    self.times = times
  }

  public init(id: Int, title: String, location: String, day: DayType, begin: Int, end: Int) {
    self.init(id: id, title: title, location: location, times: [.init(day: day, begin: begin, end: end)])
  }

  private enum CodingKeys: String, CodingKey {
    case id, title, location, times
    // Offline caches and watch transfers from before `times` held a single range.
    case day, begin, end
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(Int.self, forKey: .id)
    title = try values.decode(String.self, forKey: .title)
    location = try values.decode(String.self, forKey: .location)
    if let times = try values.decodeIfPresent([TimetableActivityTime].self, forKey: .times) {
      self.times = times
    } else {
      times = [.init(
        day: try values.decode(DayType.self, forKey: .day),
        begin: try values.decode(Int.self, forKey: .begin),
        end: try values.decode(Int.self, forKey: .end)
      )]
    }
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: CodingKeys.self)
    try values.encode(id, forKey: .id)
    try values.encode(title, forKey: .title)
    try values.encode(location, forKey: .location)
    try values.encode(times, forKey: .times)
  }

  public var backgroundColor: Color {
    TimetableTheme.current.color(forActivityID: id)
  }

  public var textColor: Color { TimetableTheme.current.textColor }

  /// Every time range, preserved so recreating the block loses none of them.
  public var draft: TimetableActivityDraft {
    .init(title: title, location: location, times: times)
  }

  /// One placeable block per time range, in the order the server gave them.
  public var slots: [TimetableActivitySlot] {
    times.indices.map { TimetableActivitySlot(activity: self, timeIndex: $0) }
  }

  public func overlaps(day: DayType, begin: Int, end: Int) -> Bool {
    times.contains { $0.overlaps(day: day, begin: begin, end: end) }
  }
}

/// One time range of an activity, for views that lay out a single block per range.
public struct TimetableActivitySlot: Identifiable, Hashable, Sendable {
  public let activity: TimetableActivity
  public let timeIndex: Int

  public init(activity: TimetableActivity, timeIndex: Int) {
    self.activity = activity
    self.timeIndex = timeIndex
  }

  public var id: String { "\(activity.id)-\(timeIndex)" }
  public var time: TimetableActivityTime { activity.times[timeIndex] }
  public var day: DayType { time.day }
  public var begin: Int { time.begin }
  public var end: Int { time.end }
  public var duration: Int { time.duration }
}

public struct TimetableActivityDraft: Hashable, Sendable {
  public var title: String
  public var location: String
  public var times: [TimetableActivityTime]

  public init(title: String, location: String, times: [TimetableActivityTime]) {
    self.title = title
    self.location = location
    self.times = times
  }

  public init(title: String, location: String, day: DayType, begin: Int, end: Int) {
    self.init(title: title, location: location, times: [.init(day: day, begin: begin, end: end)])
  }

  /// A title and at least one valid time, none of which overlap one another.
  public var isValid: Bool {
    !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !times.isEmpty
      && times.allSatisfy(\.isValid)
      && !times.indices.contains { index in times[(index + 1)...].contains(where: times[index].overlaps) }
  }

  public func overlaps(day: DayType, begin: Int, end: Int) -> Bool {
    times.contains { $0.overlaps(day: day, begin: begin, end: end) }
  }

  public func hasConflict(in timetable: Timetable, excluding activityID: Int? = nil) -> Bool {
    timetable.lectures.flatMap(\.classes).contains { overlaps(day: $0.day, begin: $0.begin, end: $0.end) }
      || timetable.activities.contains { activity in
        activity.id != activityID && activity.times.contains { overlaps(day: $0.day, begin: $0.begin, end: $0.end) }
      }
  }
}

public extension Timetable {
  /// Every activity time range on `day` with a positive length.
  func activitySlots(day: DayType) -> [TimetableActivitySlot] {
    activities.flatMap(\.slots).filter { $0.day == day && $0.duration > 0 }
  }
}

public enum TimetableActivityError: LocalizedError {
  case invalidTimeOrTitle
  case overlap
  case refreshRequired

  public var errorDescription: String? {
    switch self {
    case .invalidTimeOrTitle: String(localized: "Title and valid time required.", bundle: .module)
    case .overlap: String(localized: "Times cannot conflict with existing classes or activities.", bundle: .module)
    case .refreshRequired: String(localized: "Saved, but unable to refresh timetable.", bundle: .module)
    }
  }
}
