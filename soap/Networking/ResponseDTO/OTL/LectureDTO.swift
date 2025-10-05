//
//  LectureDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

struct LectureDTO: Codable {
  let id: Int
  let title: String
  let enTitle: String
  let course: Int
  let oldCode: String
  let classNumber: String
  let year: Int
  let semester: Int
  let code: String
  let department: Int
  let departmentCode: String
  let departmentName: String
  let departmentEnName: String
  let type: String
  let enType: String
  let limit: Int
  let numPeople: Int
  let isEnglish: Bool
  let credit: Int
  let creditAu: Int
  let commonTitle: String
  let commonEnTitle: String
  let classTitle: String
  let classEnTitle: String
  let reviewTotalWeight: Double?
  let grade: Double?
  let load: Double?
  let speech: Double?
  let professors: [ProfessorDTO]
  let classTimes: [ClassTimeDTO]?
  let examTimes: [ExamTimeDTO]?

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


extension LectureDTO {
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
