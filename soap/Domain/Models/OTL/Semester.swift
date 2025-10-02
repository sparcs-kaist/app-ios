//
//  Semester.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

struct Semester: Identifiable, Comparable, Equatable, Hashable {
  var id: String {
    "\(year)-\(semesterType.rawValue)"
  }
  let year: Int
  let semesterType: SemesterType
  let beginDate: Date
  let endDate: Date
  let eventDate: SemesterEventDate

  var description: String {
    "\(year) \(semesterType.description)"
  }

  // Comparable
  static func < (lhs: Semester, rhs: Semester) -> Bool {
    return (lhs.year != rhs.year) ? lhs.year < rhs.year : lhs.semesterType < rhs.semesterType
  }

  // Equatable
  static func == (lhs: Semester, rhs: Semester) -> Bool {
    return lhs.year == rhs.year && lhs.semesterType == rhs.semesterType
  }
}

struct SemesterEventDate: Hashable {
  let registrationPeriodStartDate: Date?
  let registrationPeriodEndDate: Date?
  let addDropPeriodEndDate: Date?
  let dropDeadlineDate: Date?
  let evaluationDeadlineDate: Date?
  let gradePostingDate: Date?
}

