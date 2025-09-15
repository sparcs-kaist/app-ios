//
//  LectureDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation

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
  let reviewTotalWeight: Double
  let grade: Double
  let load: Double
  let speech: Double
  let professors: [ProfessorDTO]
  let classtimes: [ClassTimeDTO]
  let examtimes: [ExamTimeDTO]?

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case enTitle
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
    case classtimes
    case examtimes
  }
}
