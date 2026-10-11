//
//  LectureSearchFilter+Query.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation
import BuddyDomain

/// The values the OTL lecture and course search endpoints expect for each filter.
extension LectureSearchFilter {
  var typeQueryValues: [String] {
    Classification.allCases.filter(classifications.contains).map(\.rawValue)
  }

  var departmentQueryValues: [Int] {
    departmentIDs.sorted()
  }

  var levelQueryValues: [Int] {
    Level.allCases.filter(levels.contains).flatMap(\.queryValues)
  }
}

private extension LectureSearchFilter.Level {
  /// The API only filters by exact hundreds, so the graduate band expands to each of its levels.
  var queryValues: [Int] {
    switch self {
    case .graduate:
      [500, 600, 700, 800, 900]
    default:
      [rawValue]
    }
  }
}
