//
//  SemesterDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

struct SemesterDTO: Codable {
  let year: Int
  let semester: Int   // 1: Spring, 2: Summer, 3: Autumn, 4: Winter
  let beginning: String
  let end: String
  let courseDescriptionSubmission: String?
  let courseRegistrationPeriodStart: String?
  let courseRegistrationPeriodEnd: String?
  let courseAddDropPeriodEnd: String?
  let courseDropDeadline: String?
  let courseEvaluationDeadline: String?
  let gradePosting: String?

  enum CodingKeys: String, CodingKey {
    case year
    case semester
    case beginning
    case end
    case courseDescriptionSubmission = "courseDesciptionSubmission"
    case courseRegistrationPeriodStart
    case courseRegistrationPeriodEnd
    case courseAddDropPeriodEnd
    case courseDropDeadline
    case courseEvaluationDeadline
    case gradePosting
  }
}


extension SemesterDTO {
  func toModel() -> Semester {
    Semester(
      year: year,
      semesterType: SemesterType.fromRawValue(semester),
      beginDate: beginning.toDate() ?? Date(),
      endDate: end.toDate() ?? Date(),
      eventDate: SemesterEventDate(
        registrationPeriodStartDate: courseRegistrationPeriodStart?.toDate(),
        registrationPeriodEndDate: courseRegistrationPeriodEnd?.toDate(),
        addDropPeriodEndDate: courseAddDropPeriodEnd?.toDate(),
        dropDeadlineDate: courseDropDeadline?.toDate(),
        evaluationDeadlineDate: courseEvaluationDeadline?.toDate(),
        gradePostingDate: gradePosting?.toDate()
      )
    )
  }
}
