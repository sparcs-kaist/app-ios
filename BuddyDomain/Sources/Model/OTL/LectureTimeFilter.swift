//
//  LectureTimeFilter.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 01/10/2026.
//

import Foundation

/// Narrows a lecture search to when its classes meet. Every part is optional: a lecture matches
/// when one of its class sessions is on `day`, starts at or after `begin`, and ends at or before
/// `end`, ignoring whichever parts are unset.
public struct LectureTimeFilter: Hashable, Sendable {
  public var day: DayType?
  /// Minutes since midnight.
  public var begin: Int?
  /// Minutes since midnight.
  public var end: Int?

  public init(day: DayType? = nil, begin: Int? = nil, end: Int? = nil) {
    self.day = day
    self.begin = begin
    self.end = end
  }

  public var isEmpty: Bool {
    day == nil && begin == nil && end == nil
  }

  /// The times offered for `begin` and `end`: every half hour of the teaching day.
  public static let selectableTimes: [Int] = Array(stride(from: 8 * 60, through: 23 * 60, by: 30))
}
