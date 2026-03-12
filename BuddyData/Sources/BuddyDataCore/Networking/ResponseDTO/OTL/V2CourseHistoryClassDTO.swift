//
//  V2CourseHistoryClassDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation
import BuddyDomain

struct V2CourseHistoryClassDTO: Codable {
  let lectureId: Int
  let subtitle: String
  let classNo: String
  let professors: [V2ProfessorDTO]
}


extension V2CourseHistoryClassDTO {
  func toModel() -> V2CourseHistoryClass {
    V2CourseHistoryClass(
      lectureID: lectureId,
      subtitle: subtitle,
      section: classNo,
      professors: professors.compactMap { $0.toModel() }
    )
  }
}
