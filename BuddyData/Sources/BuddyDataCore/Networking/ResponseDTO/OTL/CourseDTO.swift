//
//  CourseDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

struct CourseDTO: Codable {
  let id: Int
  let name: String
  let summary: String
  let code: String
  let type: String
  let department: DepartmentDTO
  let history: [CourseHistoryDTO]
  let classDuration: Int
  let expDuration: Int
  let credit: Int
  let creditAU: Int
}


extension CourseDTO {
  func toModel() -> Course {
    Course(
      id: id,
      name: name,
      summary: summary,
      code: code,
      type: LectureType.fromRawValue(type),
      department: department.toModel(),
      history: history.compactMap { $0.toModel() },
      classDuration: classDuration,
      expDuration: expDuration,
      credit: credit,
      creditAU: creditAU
    )
  }
}
