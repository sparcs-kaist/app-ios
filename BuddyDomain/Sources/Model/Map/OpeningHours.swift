//
//  OpeningHours.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation

/// Weekly opening hours, keyed by `Calendar` weekday (1 = Sunday … 7 = Saturday).
///
/// Mirrors the `sun: [0900, 1800]` rows in the POI sheet: a day with no intervals is closed.
public struct OpeningHours: Hashable, Sendable {
  public struct Interval: Hashable, Sendable {
    /// Minutes since midnight.
    public let opens: Int
    /// Minutes since midnight; 1440 means midnight at the end of the day.
    public let closes: Int

    public init(opens: Int, closes: Int) {
      self.opens = opens
      self.closes = closes
    }

    public init(_ opens: (Int, Int), _ closes: (Int, Int)) {
      self.init(opens: opens.0 * 60 + opens.1, closes: closes.0 * 60 + closes.1)
    }

    public static let allDay = Interval(opens: 0, closes: 1440)
  }

  public let weekly: [Int: [Interval]]

  public init(weekly: [Int: [Interval]]) {
    self.weekly = weekly
  }

  public static func everyDay(_ intervals: Interval...) -> OpeningHours {
    OpeningHours(weekly: Dictionary(uniqueKeysWithValues: (1...7).map { ($0, intervals) }))
  }

  public static func weekdays(_ intervals: Interval..., saturday: [Interval] = [], sunday: [Interval] = []) -> OpeningHours {
    var weekly = Dictionary(uniqueKeysWithValues: (2...6).map { ($0, intervals) })
    weekly[7] = saturday
    weekly[1] = sunday
    return OpeningHours(weekly: weekly)
  }

  public func intervals(on weekday: Int) -> [Interval] {
    weekly[weekday] ?? []
  }

  public var isAlwaysOpen: Bool {
    (1...7).allSatisfy { intervals(on: $0) == [.allDay] }
  }

  public func status(at date: Date, calendar: Calendar = .current) -> OpeningStatus {
    if isAlwaysOpen { return .alwaysOpen }

    let weekday = calendar.component(.weekday, from: date)
    let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)

    if let current = intervals(on: weekday).first(where: { $0.opens <= minute && minute < $0.closes }) {
      return current.closes - minute <= 30 ? .closingSoon(closes: current.closes) : .open(closes: current.closes)
    }

    if let later = intervals(on: weekday).first(where: { $0.opens > minute }) {
      return .closed(opens: later.opens, dayOffset: 0)
    }
    for offset in 1...7 {
      let day = (weekday - 1 + offset) % 7 + 1
      if let first = intervals(on: day).first {
        return .closed(opens: first.opens, dayOffset: offset)
      }
    }
    return .closed(opens: nil, dayOffset: 0)
  }
}

public enum OpeningStatus: Hashable, Sendable {
  case alwaysOpen
  case open(closes: Int)
  case closingSoon(closes: Int)
  /// `opens` is minutes since midnight, `dayOffset` days from today; `nil` when it never opens.
  case closed(opens: Int?, dayOffset: Int)

  public var isOpen: Bool {
    switch self {
    case .alwaysOpen, .open, .closingSoon: true
    case .closed: false
    }
  }
}
