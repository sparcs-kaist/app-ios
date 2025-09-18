//
//  CourseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation

struct CourseDTO: Codable {
  let id: Int
  let code: String
  let department: DepartmentDTO
  let type: String
  let enType: String
  let title: String
  let enTitle: String
  let summary: String
  let reviewTotalWeight: Double

  enum CodingKeys: String, CodingKey {
    case id
    case code = "old_code"
    case department
    case type
    case enType
    case title
    case enTitle
    case summary
    case reviewTotalWeight
  }
}


extension CourseDTO {
  func toModel() -> Course {
    Course(
      id: id,
      code: code,
      department: department.toModel(),
      type: LocalizedString([
        "ko": type,
        "en": enType
      ]),
      title: LocalizedString([
        "ko": title,
        "en": enTitle
      ]),
      summary: summary,
      reviewTotalWeight: reviewTotalWeight
    )
  }
}
