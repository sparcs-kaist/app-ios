//
//  Semester.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

public struct Semester: Identifiable, Comparable, Equatable, Hashable, Sendable {
  public var id: String {
    "\(year)-\(semesterType.rawValue)"
  }
  public let year: Int
  public let semesterType: SemesterType
  public let beginDate: Date
  public let endDate: Date
  public let eventDate: SemesterEventDate

  public var description: String {
    "\(year) \(semesterType.description)"
  }

  // Comparable
  public static func < (lhs: Semester, rhs: Semester) -> Bool {
    return (lhs.year != rhs.year) ? lhs.year < rhs.year : lhs.semesterType < rhs.semesterType
  }

  // Equatable
  public static func == (lhs: Semester, rhs: Semester) -> Bool {
    return lhs.year == rhs.year && lhs.semesterType == rhs.semesterType
  }

  public init(
    year: Int,
    semesterType: SemesterType,
    beginDate: Date,
    endDate: Date,
    eventDate: SemesterEventDate
  ) {
    self.year = year
    self.semesterType = semesterType
    self.beginDate = beginDate
    self.endDate = endDate
    self.eventDate = eventDate
  }
}

public struct SemesterEventDate: Hashable, Sendable {
  public let registrationPeriodStartDate: Date?
  public let registrationPeriodEndDate: Date?
  public let addDropPeriodEndDate: Date?
  public let dropDeadlineDate: Date?
  public let evaluationDeadlineDate: Date?
  public let gradePostingDate: Date?

  public init(
    registrationPeriodStartDate: Date?,
    registrationPeriodEndDate: Date?,
    addDropPeriodEndDate: Date?,
    dropDeadlineDate: Date?,
    evaluationDeadlineDate: Date?,
    gradePostingDate: Date?
  ) {
    self.registrationPeriodStartDate = registrationPeriodStartDate
    self.registrationPeriodEndDate = registrationPeriodEndDate
    self.addDropPeriodEndDate = addDropPeriodEndDate
    self.dropDeadlineDate = dropDeadlineDate
    self.evaluationDeadlineDate = evaluationDeadlineDate
    self.gradePostingDate = gradePostingDate
  }
}

