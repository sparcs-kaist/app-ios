//
//  CourseSummaryDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

struct CourseSummaryDTO: Codable {
  let id: Int
  let code: String
  let name: String
  let summary: String
  let department: DepartmentDTO
  let professors: [ProfessorDTO]
  let type: String
  let completed: Bool
  let open: Bool
}

extension CourseSummaryDTO {
  func toModel() -> CourseSummary {
    CourseSummary(
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
