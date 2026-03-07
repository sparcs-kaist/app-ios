//
//  V2Lecture.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import SwiftUI

public struct V2Lecture: Identifiable, CourseRepresentable, Hashable, Sendable, Codable {
  public let id: Int
  public let courseID: Int
  public let section: String
  public let name: String
  public let subtitle: String
  public let code: String
  public let department: V2Department
  public let type: LectureType
  public let capacity: Int
  public let enrolledCount: Int
  public let credit: Int
  public let creditAU: Int
  public let grade: Double
  public let load: Double
  public let speech: Double
  public let isEnglish: Bool
  public let professors: [V2Professor]
  public let classes: [V2LectureClass]
  public let exams: [V2LectureExam]
  public let classDuration: Int
  public let expDuration: Int

  // Background colour for TimetableGridCell
  public var backgroundColor: Color {
    let index = courseID % TimetableColorPalette.palettes[0].colors.count
    return TimetableColorPalette.palettes[0].colors[index]
  }

  // Text colour for TimetableGridCell
  public var textColor: Color {
    return TimetableColorPalette.palettes[0].textColor
  }

  public init(
    id: Int,
    courseID: Int,
    section: String,
    name: String,
    subtitle: String,
    code: String,
    department: V2Department,
    type: LectureType,
    capacity: Int,
    enrolledCount: Int,
    credit: Int,
    creditAU: Int,
    grade: Double,
    load: Double,
    speech: Double,
    isEnglish: Bool,
    professors: [V2Professor],
    classes: [V2LectureClass],
    exams: [V2LectureExam],
    classDuration: Int,
    expDuration: Int
  ) {
    self.id = id
    self.courseID = courseID
    self.section = section
    self.name = name
    self.subtitle = subtitle
    self.code = code
    self.department = department
    self.type = type
    self.capacity = capacity
    self.enrolledCount = enrolledCount
    self.credit = credit
    self.creditAU = creditAU
    self.grade = grade
    self.load = load
    self.speech = speech
    self.isEnglish = isEnglish
    self.professors = professors
    self.classes = classes
    self.exams = exams
    self.classDuration = classDuration
    self.expDuration = expDuration
  }
}
