//
//  V2LectureDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

public struct V2LectureDTO: Codable {
  public let id: Int
  public let courseId: Int
  public let classNo: String
  public let name: String
  public let subtitle: String
  public let code: String
  public let department: V2DepartmentDTO
  public let type: String
  public let limitPeople: Int
  public let numPeople: Int
  public let credit: Int
  public let creditAU: Int
  public let averageGrade: Double
  public let averageLoad: Double
  public let averageSpeech: Double
  public let isEnglish: Bool
  public let professors: [V2ProfessorDTO]
  public let classes: [V2LectureClassDTO]
  public let examTimes: [V2LectureExamDTO]
  public let classDuration: Int
  public let expDuration: Int
}


public extension V2LectureDTO {
  func toModel() -> V2Lecture {
    V2Lecture(
      id: id,
      courseID: courseId,
      section: classNo,
      name: name,
      subtitle: subtitle,
      code: code,
      department: department.toModel(),
      type: LectureType(rawValue: type) ?? .etc,
      capacity: limitPeople,
      enrolledCount: numPeople,
      credit: credit,
      creditAU: creditAU,
      grade: averageGrade,
      load: averageLoad,
      speech: averageSpeech,
      isEnglish: isEnglish,
      professors: professors.compactMap { $0.toModel() },
      classes: classes.compactMap { $0.toModel() },
      exams: examTimes.compactMap { $0.toModel() },
      classDuration: classDuration,
      expDuration: expDuration
    )
  }
}
