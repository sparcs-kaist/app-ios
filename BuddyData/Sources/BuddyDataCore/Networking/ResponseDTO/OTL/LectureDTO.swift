//
//  LectureDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

public struct LectureDTO: Codable {
  public let id: Int
  public let title: String
  public let enTitle: String
  public let course: Int
  public let oldCode: String
  public let classNumber: String
  public let year: Int
  public let semester: Int
  public let code: String
  public let department: Int
  public let departmentCode: String
  public let departmentName: String
  public let departmentEnName: String
  public let type: String
  public let enType: String
  public let limit: Int
  public let numPeople: Int
  public let isEnglish: Bool
  public let credit: Int
  public let creditAu: Int
  public let commonTitle: String
  public let commonEnTitle: String
  public let classTitle: String
  public let classEnTitle: String
  public let reviewTotalWeight: Double?
  public let grade: Double?
  public let load: Double?
  public let speech: Double?
  public let professors: [ProfessorDTO]
  public let classTimes: [ClassTimeDTO]?
  public let examTimes: [ExamTimeDTO]?

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case enTitle = "title_en"
    case course
    case oldCode = "old_code"
    case classNumber = "class_no"
    case year
    case semester
    case code
    case department
    case departmentCode = "department_code"
    case departmentName = "department_name"
    case departmentEnName = "department_name_en"
    case type
    case enType = "type_en"
    case limit
    case numPeople = "num_people"
    case isEnglish = "is_english"
    case credit
    case creditAu = "credit_au"
    case commonTitle = "common_title"
    case commonEnTitle = "common_title_en"
    case classTitle = "class_title"
    case classEnTitle = "class_title_en"
    case reviewTotalWeight = "review_total_weight"
    case grade
    case load
    case speech
    case professors
    case classTimes = "classtimes"
    case examTimes = "examtimes"
  }
}


public extension LectureDTO {
  func toModel() -> Lecture {
    Lecture(
      id: id,
      course: course,
      code: code,
      section: classNumber,
      year: year,
      semester: SemesterType.fromRawValue(semester),
      title: LocalizedString([
        "ko": title,
        "en": enTitle
      ]),
      department: Department(id: department, name: LocalizedString([
        "ko": departmentName,
        "en": departmentEnName
      ]), code: code),
      isEnglish: isEnglish,
      credit: credit,
      creditAu: creditAu,
      capacity: limit,
      numberOfPeople: numPeople,
      grade: grade ?? 0.0,
      load: load ?? 0.0,
      speech: speech ?? 0.0,
      reviewTotalWeight: reviewTotalWeight ?? 0.0,
      type: LectureType.fromRawValue(enType),
      typeDetail: LocalizedString([
        "ko": type,
        "en": enType
      ]),
      professors: professors.compactMap { $0.toModel() },
      classTimes: classTimes?.compactMap { $0.toModel() } ?? [],
      examTimes: examTimes?.compactMap { $0.toModel() } ?? []
    )
  }
}
