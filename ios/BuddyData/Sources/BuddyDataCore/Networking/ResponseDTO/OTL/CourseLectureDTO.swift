//
//  CourseLectureDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation
import BuddyDomain

struct CourseLectureDTO: Codable {
  let id: Int
  let name: String
  let code: String
  let type: String
  let lectures: [LectureDTO]
  let completed: Bool
}


extension CourseLectureDTO {
  func toModel() -> CourseLecture {
    CourseLecture(
      id: id,
      name: name,
      code: code,
      type: LectureType.fromRawValue(type),
      lectures: lectures.compactMap { $0.toModel() },
      completed: completed
    )
  }
}
