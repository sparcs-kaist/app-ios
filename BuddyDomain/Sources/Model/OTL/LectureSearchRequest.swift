//
//  LectureSearchRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation

public struct LectureSearchRequest {
  public let year: Int
  public let semester: Int
  public let department: [String]
  public let level: [String]
  public let keyword: String
  public let limit: Int
  public let offset: Int

  public init(
    year: Int,
    semester: Int,
    department: [String],
    level: [String],
    keyword: String,
    limit: Int,
    offset: Int
  ) {
    self.year = year
    self.semester = semester
    self.department = department
    self.level = level
    self.keyword = keyword
    self.limit = limit
    self.offset = offset
  }
}
