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
  let department: [Int]
  let level: [Int]
  let limit: Int
  let offset: Int
}


extension LectureSearchRequestDTO {
  static func fromModel(model: LectureSearchRequest) -> LectureSearchRequestDTO {
    LectureSearchRequestDTO(
      year: model.semester.year,
      semester: model.semester.semesterType.intValue,
      keyword: model.keyword,
      type: LectureSearchFilter.Classification.allCases
        .filter(model.filter.classifications.contains)
        .map(\.rawValue),
      department: model.filter.departmentIDs.sorted(),
      level: LectureSearchFilter.Level.allCases
        .filter(model.filter.levels.contains)
        .flatMap(\.queryValues),
      limit: model.limit,
      offset: model.offset
    )
  }

  /// Query parameters for `GET /api/v2/lectures`. Unused options are left out so the server
  /// treats them as "any".
  var parameters: [String: Any] {
    var parameters: [String: Any] = [
      "year": year,
      "semester": semester,
      "limit": limit,
      "offset": offset
    ]
    if !keyword.isEmpty { parameters["keyword"] = keyword }
    if !type.isEmpty { parameters["type"] = type }
    if !department.isEmpty { parameters["department"] = department }
    if !level.isEmpty { parameters["level"] = level }

    return parameters
  }
}

private extension LectureSearchFilter.Level {
  /// The API only filters by exact hundreds, so the graduate band expands to each of its levels.
  var queryValues: [Int] {
    switch self {
    case .graduate:
      [500, 600, 700, 800, 900]
    default:
      [rawValue]
    }
  }
}
