//
//  CourseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation
import BuddyDomain

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
  let grade: Double?
  let load: Double?
  let speech: Double?
  let credit: Int
  let creditAu: Int
  let numClasses: Int
  let numLabs: Int

  enum CodingKeys: String, CodingKey {
    case id
    case code = "old_code"
    case department
    case type
    case enType = "type_en"
    case title
    case enTitle = "title_en"
    case summary
    case reviewTotalWeight = "review_total_weight"
    case grade
    case load
    case speech
    case credit
    case creditAu = "credit_au"
    case numClasses = "num_classes"
    case numLabs = "num_labs"
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
      reviewTotalWeight: reviewTotalWeight,
      grade: grade ?? 0.0,
      load: load ?? 0.0,
      speech: speech ?? 0.0,
      credit: credit,
      creditAu: creditAu,
      numClasses: numClasses,
      numLabs: numLabs
    )
  }
}
