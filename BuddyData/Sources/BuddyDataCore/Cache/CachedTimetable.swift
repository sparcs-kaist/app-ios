//
//  CachedTimetable.swift
//  BuddyData
//
//  Created by Claude on 11/03/2026.
//

import Foundation
import SwiftData
import BuddyDomain

/// SwiftData record for timetables and the widget's timetable list, cleared together on sign-out.
///
/// Cache keys:
///  - by timetable ID   → `cacheKey = "\(timetableID)"`
///  - "my table"        → `cacheKey = "\(year)-\(semesterRawValue)-myTable"`
///  - current "my table" → `cacheKey = "current-myTable"`
///  - widget options    → `cacheKey = "timetable-list"`
///  - app navigation    → `semesters`, `current-semester`, `"\(semester.id)-summaries"`
@Model
public final class CachedTimetable {
  /// Unique lookup key for the timetable or reserved widget metadata record.
  @Attribute(.unique)
  public var cacheKey: String

  /// JSON-encoded timetable or navigation data, decoded according to its cache key.
  public var data: Data

  /// When this entry was last written.
  public var updatedAt: Date

  public init(cacheKey: String, data: Data, updatedAt: Date = .now) {
    self.cacheKey = cacheKey
    self.data = data
    self.updatedAt = updatedAt
  }
}
