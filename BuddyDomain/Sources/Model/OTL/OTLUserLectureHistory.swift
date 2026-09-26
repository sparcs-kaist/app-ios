//
//  OTLUserLectureHistory.swift
//  BuddyDomain
//

import Foundation

/// Lectures a user has taken, grouped by semester.
public struct OTLUserLectureHistory: Hashable, Sendable {
  public let semesters: [OTLUserLectureSemester]
  public let totalLecturesCount: Int
  public let reviewedLecturesCount: Int
  public let totalLikesCount: Int

  public init(
    semesters: [OTLUserLectureSemester],
    totalLecturesCount: Int,
    reviewedLecturesCount: Int,
    totalLikesCount: Int
  ) {
    self.semesters = semesters
    self.totalLecturesCount = totalLecturesCount
    self.reviewedLecturesCount = reviewedLecturesCount
    self.totalLikesCount = totalLikesCount
  }
}

public struct OTLUserLectureSemester: Identifiable, Hashable, Sendable {
  public var id: String { "\(year)-\(semesterType.rawValue)" }

  public let year: Int
  public let semesterType: SemesterType
  public let lectures: [OTLTakenLecture]

  public init(year: Int, semesterType: SemesterType, lectures: [OTLTakenLecture]) {
    self.year = year
    self.semesterType = semesterType
    self.lectures = lectures
  }
}

public struct OTLTakenLecture: Identifiable, Hashable, Sendable {
  public var id: Int { lectureID }

  public let courseID: Int
  public let lectureID: Int
  public let name: String
  public let code: String
  public let professors: [Professor]
  public let hasWrittenReview: Bool

  public init(
    courseID: Int,
    lectureID: Int,
    name: String,
    code: String,
    professors: [Professor],
    hasWrittenReview: Bool
  ) {
    self.courseID = courseID
    self.lectureID = lectureID
    self.name = name
    self.code = code
    self.professors = professors
    self.hasWrittenReview = hasWrittenReview
  }
}
