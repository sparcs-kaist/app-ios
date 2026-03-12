//
//  V2CourseHistory.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

public struct V2CourseHistory: Hashable, Sendable, Codable {
  public let year: Int
  public let semester: SemesterType
  public let classes: [V2CourseHistoryClass]
  public let myLectureID: Int?

  public init(
    year: Int,
    semester: SemesterType,
    classes: [V2CourseHistoryClass],
    myLectureID: Int?
  ) {
    self.year = year
    self.semester = semester
    self.classes = classes
    self.myLectureID = myLectureID
  }
}
