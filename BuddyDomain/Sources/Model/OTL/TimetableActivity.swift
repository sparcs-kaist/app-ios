import Foundation
import SwiftUI

/// A custom timetable block, separate from academic lectures and their credits.
public struct TimetableActivity: Identifiable, Hashable, Codable, Sendable {
  public let id: Int
  public var title: String
  public var location: String
  public var day: DayType
  public var begin: Int
  public var end: Int

  public init(id: Int, title: String, location: String, day: DayType, begin: Int, end: Int) {
    self.id = id
    self.title = title
    self.location = location
    self.day = day
    self.begin = begin
    self.end = end
  }

  public var backgroundColor: Color {
    let colors = TimetableColorPalette.palettes[0].colors
    let index = ((id % colors.count) + colors.count) % colors.count
    return colors[index]
  }

  public var textColor: Color { TimetableColorPalette.palettes[0].textColor }
  public var duration: Int { end - begin }
  public var draft: TimetableActivityDraft {
    .init(title: title, location: location, day: day, begin: begin, end: end)
  }
}

public struct TimetableActivityDraft: Hashable, Sendable {
  public var title: String
  public var location: String
  public var day: DayType
  public var begin: Int
  public var end: Int

  public init(title: String, location: String, day: DayType, begin: Int, end: Int) {
    self.title = title
    self.location = location
    self.day = day
    self.begin = begin
    self.end = end
  }

  public var isValid: Bool {
    !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && begin >= 0 && end <= 1440 && begin < end
  }

  public func overlaps(day: DayType, begin: Int, end: Int) -> Bool {
    self.day == day && self.begin < end && begin < self.end
  }

  public func hasConflict(in timetable: Timetable, excluding activityID: Int? = nil) -> Bool {
    timetable.lectures.flatMap(\.classes).contains { overlaps(day: $0.day, begin: $0.begin, end: $0.end) }
      || timetable.activities.contains { $0.id != activityID && overlaps(day: $0.day, begin: $0.begin, end: $0.end) }
  }
}

public enum TimetableActivityError: LocalizedError {
  case invalidTimeOrTitle
  case overlap
  case refreshRequired

  public var errorDescription: String? {
    switch self {
    case .invalidTimeOrTitle: String(localized: "Enter a title and a valid time within one day.", bundle: .module)
    case .overlap: String(localized: "Activities can’t overlap classes or other activities.", bundle: .module)
    case .refreshRequired: String(localized: "Your change was saved, but the timetable couldn’t refresh. Try refreshing again.", bundle: .module)
    }
  }
}
