//
//  V2CourseDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

struct V2CourseDTO: Codable {
  let id: Int
  let name: String
  let summary: String
  let code: String
  let type: String
  let department: V2DepartmentDTO
  let history: [V2CourseHistoryDTO]
  let classDuration: Int
  let expDuration: Int
  let credit: Int
  let creditAU: Int
}


extension V2CourseDTO {
  func toModel() -> V2Course {
    V2Course(
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
