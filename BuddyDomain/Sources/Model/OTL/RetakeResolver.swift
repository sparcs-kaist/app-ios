//
//  RetakeResolver.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import Foundation

/// Picks which attempt of a retaken course counts toward cumulative GPA and credits.
///
/// Attempts are grouped by lecture code. Per group:
/// 1. NR attempts are off the record and never count.
/// 2. Otherwise the highest-graded attempt counts (P ranks above F; ties go to the
///    later attempt), and the others are ignored for both GPA and credits.
/// 3. An attempt without a grade yet — typically a retake in progress — counts only
///    when no other attempt passed, so a failed course being retaken counts once.
public enum RetakeResolver {
  /// The lectures that count, in their original order.
  /// - Parameter lectures: Every attempt, oldest semester first.
  public static func countedLectures(_ lectures: [Lecture], grades: [Int: LectureGrade]) -> [Lecture] {
    var countedIDs = Set<Int>()

    for attempts in Dictionary(grouping: lectures, by: \.code).values {
      guard attempts.count > 1 else {
        countedIDs.formUnion(attempts.map(\.id))
        continue
      }

      let onRecord = attempts.filter { grades[$0.id] != .nonRecord }
      // Later attempts win ties, so scan newest first and keep the first maximum.
      let graded = onRecord.reversed().filter { grades[$0.id] != nil }
      let best = graded.max { rank(grades[$0.id]) < rank(grades[$1.id]) }
      let pending = onRecord.last { grades[$0.id] == nil }

      if let best, isPassed(grades[best.id]) {
        countedIDs.insert(best.id)
      } else if let pending {
        countedIDs.insert(pending.id)
      } else if let best {
        countedIDs.insert(best.id)
      }
    }

    return lectures.filter { countedIDs.contains($0.id) }
  }

  /// Attempts replaced by another attempt of the same course, which don't count.
  /// NR attempts are left out: their grade already says they're off the record.
  public static func supersededLectureIDs(_ lectures: [Lecture], grades: [Int: LectureGrade]) -> Set<Int> {
    let countedIDs = Set(countedLectures(lectures, grades: grades).map(\.id))
    let retakenCodes = Set(Dictionary(grouping: lectures, by: \.code).filter { $0.value.count > 1 }.keys)
    return Set(
      lectures
        .filter { retakenCodes.contains($0.code) && !countedIDs.contains($0.id) && grades[$0.id] != .nonRecord }
        .map(\.id)
    )
  }

  /// Higher is better. Letter grades and F by grade point; P and S just above F.
  private static func rank(_ grade: LectureGrade?) -> Double {
    switch grade {
    case .pass, .satisfied: 0.5
    case .unsatisfied: 0
    case let grade?: grade.gradePoint ?? 0
    case nil: -1
    }
  }

  private static func isPassed(_ grade: LectureGrade?) -> Bool {
    switch grade {
    case .fail, .unsatisfied, .nonRecord, nil: false
    default: true
    }
  }
}
