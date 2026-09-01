//
//  CourseHistoryDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation
import BuddyDomain

struct CourseHistoryDTO: Codable {
  let year: Int
  let semester: Int
  let classes: [CourseHistoryClassDTO]
  let myLectureId: Int?
}

extension CourseHistoryDTO {
  func toModel() -> CourseHistory {
    CourseHistory(
      year: year,
      semester: SemesterType.fromRawValue(semester),
      classes: classes.compactMap { $0.toModel() },
      myLectureID: myLectureId
    )
  }
}
