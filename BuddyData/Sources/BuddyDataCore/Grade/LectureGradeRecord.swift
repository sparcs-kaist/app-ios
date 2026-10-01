//
//  LectureGradeRecord.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import Foundation
import SwiftData

/// SwiftData record of the grade a user entered for one lecture.
///
/// Kept in its own store, separate from `CachedTimetable`, so clearing the
/// timetable cache on sign-out never deletes grades the user typed in.
@Model
public final class LectureGradeRecord {
  #Unique<LectureGradeRecord>([\.userID, \.lectureID])

  /// OTL user ID (`OTLUser.id`) the grade belongs to.
  public var userID: Int = 0

  /// OTL lecture ID. Lecture IDs are unique per semester offering.
  public var lectureID: Int

  /// `LectureGrade.rawValue`.
  public var gradeRawValue: String

  public var updatedAt: Date

  public init(userID: Int, lectureID: Int, gradeRawValue: String, updatedAt: Date = .now) {
    self.userID = userID
    self.lectureID = lectureID
    self.gradeRawValue = gradeRawValue
    self.updatedAt = updatedAt
  }
}
