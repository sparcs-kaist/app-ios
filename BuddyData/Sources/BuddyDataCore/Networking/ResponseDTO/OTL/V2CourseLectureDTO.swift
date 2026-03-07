//
//  V2CourseLectureDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation
import BuddyDomain

struct V2CourseLectureDTO: Codable {
  let id: Int
  let name: String
  let code: String
  let type: String
  let lectures: [V2LectureDTO]
  let completed: Bool
}


extension V2CourseLectureDTO {
  func toModel() -> V2CourseLecture {
    V2CourseLecture(
      id: id,
      name: name,
      code: code,
      type: LectureType.fromRawValue(type),
      lectures: lectures.compactMap { $0.toModel() },
      completed: completed
    )
  }
}
