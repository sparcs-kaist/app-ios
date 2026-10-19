//
//  ParsedActivity.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation

/// A timetable activity as the on-device model reads it from a description
/// such as "Study group every Tuesday 7–9pm at the library".
///
/// Anything the description doesn't mention is `nil`, so the form keeps what it
/// already had there. Times are candidates, not guarantees: the form still
/// snaps them to its quarter hours and keeps them within the day.
public struct ParsedActivity: Equatable, Sendable {
  public var title: String?
  public var location: String?
  /// Every day it meets on, in the order named, e.g. all seven for "every day".
  public var days: [DayType]
  /// Minutes from midnight.
  public var begin: Int?
  /// Minutes from midnight, after `begin`.
  public var end: Int?
  /// Any times after the first, for a description that names several, such as
  /// "아침 7시, 저녁 9시". Empty unless `begin` is set.
  public var laterTimes: [Time] = []

  /// A start, in minutes from midnight, and an end when one was given.
  public struct Time: Equatable, Sendable {
    public var begin: Int
    public var end: Int?

    public init(begin: Int, end: Int? = nil) {
      self.begin = begin
      self.end = end
    }
  }

  public init(
    title: String? = nil,
    location: String? = nil,
    day: DayType? = nil,
    days: [DayType] = [],
    begin: Int? = nil,
    end: Int? = nil
  ) {
    self.title = title
    self.location = location
    self.days = days.isEmpty ? day.map { [$0] } ?? [] : days
    self.begin = begin
    self.end = end
  }

  /// The first day it meets on.
  public var day: DayType? {
    get { days.first }
    set { days = newValue.map { [$0] } ?? [] }
  }

  /// From the clock times the model gives, which it is asked for on a 24-hour
  /// clock but can still get wrong.
  ///
  /// An end at or before the start is read as the same time twelve hours later
  /// when that fits in the day, since "7 to 9" from someone meaning the evening
  /// can come back as 19:00 to 9:00. Failing an end time, a length is used.
  public init(
    title: String?,
    location: String?,
    day: DayType? = nil,
    days: [DayType] = [],
    startHour: Int?,
    startMinute: Int?,
    endHour: Int?,
    endMinute: Int?,
    durationMinutes: Int?
  ) {
    let begin = Self.minutes(hour: startHour, minute: startMinute)
    var end = Self.minutes(hour: endHour, minute: endMinute)
    if let begin, let current = end, current <= begin {
      let later = current + 12 * 60
      end = later > begin && later <= Self.minutesInDay ? later : nil
    }
    if end == nil, let begin, let durationMinutes, durationMinutes > 0 {
      end = min(begin + durationMinutes, Self.minutesInDay)
    }
    if begin == nil {
      // An end with no start says nothing about where the activity sits.
      end = nil
    }

    self.init(
      title: Self.cleaned(title),
      location: Self.cleaned(location),
      day: day,
      days: days,
      begin: begin,
      end: end
    )
  }

  /// Whether the description gave anything to fill in.
  public var isEmpty: Bool {
    title == nil && location == nil && days.isEmpty && begin == nil
  }

  private static let minutesInDay = 24 * 60

  private static func minutes(hour: Int?, minute: Int?) -> Int? {
    guard let hour, (0...23).contains(hour) else { return nil }
    let minute = minute.map { min(max($0, 0), 59) } ?? 0
    return hour * 60 + minute
  }

  private static func cleaned(_ text: String?) -> String? {
    guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
    return text
  }
}

/// Why a description could not fill in an activity. Only `failed` is worth
/// retrying unchanged.
public enum ActivityParsingError: Error, Equatable, Sendable {
  /// The device doesn't support Apple Intelligence, it is switched off, or the
  /// model is still downloading.
  case unavailable
  /// The description tripped the model's safety guardrails.
  case unsafeRequest
  /// The description named nothing the form has a field for.
  case nothingFound
  case failed
}
