//
//  CachedTimetable.swift
//  BuddyData
//
//  Created by Claude on 11/03/2026.
//

import Foundation
import SwiftData
import BuddyDomain

/// SwiftData model that stores a serialised Timetable for offline / cached access.
///
/// Two kinds of timetable are cached:
///  - by timetable ID   → `cacheKey = "\(timetableID)"`
///  - "my table"        → `cacheKey = "\(year)-\(semesterRawValue)-myTable"`
@Model
public final class CachedTimetable {
  /// Unique lookup key – matches the `Timetable.id` produced by the repository.
  @Attribute(.unique)
  public var cacheKey: String

  /// JSON-encoded `Timetable`.
  public var data: Data

  /// When this entry was last written.
  public var updatedAt: Date

  public init(cacheKey: String, data: Data, updatedAt: Date = .now) {
    self.cacheKey = cacheKey
    self.data = data
    self.updatedAt = updatedAt
  }
}
