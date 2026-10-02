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
/// 2. Otherwise the latest attempt counts, overwriting every earlier grade — even a
///    better one — and the earlier attempts are ignored for both GPA and credits.
///    A retake still in progress (no grade yet) counts too.
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

      if let latest = attempts.last(where: { grades[$0.id] != .nonRecord }) {
        countedIDs.insert(latest.id)
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
}
