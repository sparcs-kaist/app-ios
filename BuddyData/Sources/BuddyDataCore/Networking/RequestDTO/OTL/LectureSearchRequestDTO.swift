//
//  LectureSearchRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation
import BuddyDomain

public struct LectureSearchRequestDTO: Codable {
  let year: Int
  let semester: Int
  let keyword: String
  let type: [String]
  let department: [String]
  let level: [String]
  let limit: Int
  let offset: Int
}


extension LectureSearchRequestDTO {
  static func fromModel(model: LectureSearchRequest) -> LectureSearchRequestDTO {
    LectureSearchRequestDTO(
      year: model.year,
      semester: model.semester,
      keyword: model.keyword,
      type: [],
      department: model.department,
      level: model.level,
      limit: model.limit,
      offset: model.offset
    )
  }
}

