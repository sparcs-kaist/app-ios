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
  let limit: Int
  let offset: Int
}


extension CourseSearchRequestDTO {
  static func fromModel(model: CourseSearchRequest) -> CourseSearchRequestDTO {
    CourseSearchRequestDTO(keyword: model.keyword, limit: model.limit, offset: model.offset)
  }
}
