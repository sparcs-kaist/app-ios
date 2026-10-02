//
//  CourseSearchRequestDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public struct CourseSearchRequestDTO: Codable {
  let keyword: String
  let type: [String]
  let department: [Int]
  let level: [Int]
  let term: Int?
  let limit: Int
  let offset: Int
}


extension CourseSearchRequestDTO {
  static func fromModel(model: CourseSearchRequest) -> CourseSearchRequestDTO {
    CourseSearchRequestDTO(
      keyword: model.keyword,
      type: model.filter.typeQueryValues,
      department: model.filter.departmentQueryValues,
      level: model.filter.levelQueryValues,
      term: model.period?.rawValue,
      limit: model.limit,
      offset: model.offset
    )
  }

  /// Query parameters for `GET /api/v2/courses`. Unused options are left out so the server
  /// treats them as "any".
  var parameters: [String: Any] {
    var parameters: [String: Any] = [
      "order": "code",
      "limit": limit,
      "offset": offset
    ]
    if !keyword.isEmpty { parameters["keyword"] = keyword }
    if !type.isEmpty { parameters["type"] = type }
    if !department.isEmpty { parameters["department"] = department }
    if !level.isEmpty { parameters["level"] = level }
    if let term { parameters["term"] = term }

    return parameters
  }
}
