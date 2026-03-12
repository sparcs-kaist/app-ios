//
//  V2CourseHistoryDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation
import BuddyDomain

struct V2CourseHistoryDTO: Codable {
  let year: Int
  let semester: Int
  let classes: [V2CourseHistoryClassDTO]
  let myLectureId: Int?
}

extension V2CourseHistoryDTO {
  func toModel() -> V2CourseHistory {
    V2CourseHistory(
      year: year,
      semester: SemesterType.fromRawValue(semester),
      classes: classes.compactMap { $0.toModel() },
      myLectureID: myLectureId
    )
  }
}
