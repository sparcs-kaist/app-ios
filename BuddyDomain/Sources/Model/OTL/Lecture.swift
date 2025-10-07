//
//  Lecture.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct Lecture: Identifiable, CourseRepresentable, Sendable, Codable {
  public let id: Int
  public let course: Int
  public let code: String
  public let section: String?
  public let year: Int
  public let semester: SemesterType
  public let title: LocalizedString
  public let department: Department
  public let isEnglish: Bool
  public let credit: Int
  public let creditAu: Int
  public let capacity: Int
  public let numberOfPeople: Int
  public let grade: Double
  public let load: Double
  public let speech: Double
  public let reviewTotalWeight: Double
  public let type: LectureType
  public let typeDetail: LocalizedString
  public let professors: [Professor]
  public let classTimes: [ClassTime]
  public let examTimes: [ExamTime]

  // Background colour for TimetableGridCell
  public var backgroundColor: Color {
    let index = course % TimetableColorPalette.palettes[0].colors.count
    return TimetableColorPalette.palettes[0].colors[index]
  }

  // Text colour for TimetableGridCell
  public var textColor: Color {
    return TimetableColorPalette.palettes[0].textColor
  }

  public init(
    id: Int,
    course: Int,
    code: String,
    section: String?,
    year: Int,
    semester: SemesterType,
    title: LocalizedString,
    department: Department,
    isEnglish: Bool,
    credit: Int,
    creditAu: Int,
    capacity: Int,
    numberOfPeople: Int,
    grade: Double,
    load: Double,
    speech: Double,
    reviewTotalWeight: Double,
    type: LectureType,
    typeDetail: LocalizedString,
    professors: [Professor],
    classTimes: [ClassTime],
    examTimes: [ExamTime]
  ) {
    self.id = id
    self.course = course
    self.code = code
    self.section = section
    self.year = year
    self.semester = semester
    self.title = title
    self.department = department
    self.isEnglish = isEnglish
    self.credit = credit
    self.creditAu = creditAu
    self.capacity = capacity
    self.numberOfPeople = numberOfPeople
    self.grade = grade
    self.load = load
    self.speech = speech
    self.reviewTotalWeight = reviewTotalWeight
    self.type = type
    self.typeDetail = typeDetail
    self.professors = professors
    self.classTimes = classTimes
    self.examTimes = examTimes
  }
}

