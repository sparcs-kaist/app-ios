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
  let code: String
  let name: String
  let summary: String
  let department: V2DepartmentDTO
  let professors: [V2ProfessorDTO]
  let type: String
  let completed: Bool
  let open: Bool
}

extension V2CourseDTO {
  func toModel() -> V2Course {
    V2Course(
      id: id,
      code: code,
      name: name,
      summary: summary,
      department: department.toModel(),
      professors: professors.compactMap { $0.toModel() },
      type: LectureType.fromRawValue(type),
      completed: completed,
      open: open
    )
  }
}
