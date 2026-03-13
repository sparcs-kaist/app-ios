//
//  CourseHistoryClassDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation
import BuddyDomain

struct CourseHistoryClassDTO: Codable {
  let lectureId: Int
  let subtitle: String
  let classNo: String
  let professors: [ProfessorDTO]
}


extension CourseHistoryClassDTO {
  func toModel() -> CourseHistoryClass {
    CourseHistoryClass(
      lectureID: lectureId,
      subtitle: subtitle,
      section: classNo,
      professors: professors.compactMap { $0.toModel() }
    )
  }
}
