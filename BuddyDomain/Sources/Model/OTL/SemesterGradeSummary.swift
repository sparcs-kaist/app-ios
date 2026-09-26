//
//  SemesterGradeSummary.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import Foundation

/// GPA and completeness of the grades entered for one semester's lectures.
public struct SemesterGradeSummary: Equatable, Sendable {
  /// Credit-weighted GPA, or `nil` when no entered grade counts toward it yet.
  public let gpa: Double?
  public let gradedCount: Int
  public let lectureCount: Int
  /// Credits (not AU) on record: every lecture except NR ones, which are left off
  /// the transcript. Ungraded lectures count, as they're assumed in progress.
  public let recordedCredits: Int
  /// Credits (not AU) counting toward graduation: recorded credits minus failed
  /// (F) ones. P credits count.
  public let earnedCredits: Int

  /// Whether every lecture in the semester has a grade entered.
  public var isComplete: Bool { gradedCount == lectureCount }

  public init(lectures: [Lecture], grades: [Int: LectureGrade]) {
    var weightedPoints = 0.0
    var gpaCredits = 0
    var gradedCount = 0
    var recordedCredits = 0
    var earnedCredits = 0

    for lecture in lectures {
      let grade = grades[lecture.id]
      if grade != .nonRecord {
        recordedCredits += lecture.credit
        if grade != .fail { earnedCredits += lecture.credit }
      }
      guard let grade = grades[lecture.id] else { continue }
      gradedCount += 1
      // AU never counts; P/NR/S/U have no grade point.
      if let point = grade.gradePoint, lecture.credit > 0 {
        weightedPoints += point * Double(lecture.credit)
        gpaCredits += lecture.credit
      }
    }

    self.gpa = gpaCredits > 0 ? weightedPoints / Double(gpaCredits) : nil
    self.gradedCount = gradedCount
    self.lectureCount = lectures.count
    self.recordedCredits = recordedCredits
    self.earnedCredits = earnedCredits
  }
}
