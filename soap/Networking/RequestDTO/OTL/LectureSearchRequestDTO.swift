//
//  LectureSearchRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation

struct LectureSearchRequestDTO: Codable {
  let year: Int
  let semester: Int
  let keyword: String
  let type: String
  let department: String
  let level: String
  let limit: Int
  let offset: Int
}


extension LectureSearchRequestDTO {
  static func fromModel(model: LectureSearchRequest) -> LectureSearchRequestDTO {
    LectureSearchRequestDTO(
      year: model.semester.year,
      semester: model.semester.semesterType.intValue,
      keyword: model.keyword,
      type: "ALL",
      department: "ALL",
      level: "ALL",
      limit: model.limit,
      offset: model.offset
    )
  }
}
