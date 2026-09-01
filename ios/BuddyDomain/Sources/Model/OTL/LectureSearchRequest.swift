//
//  LectureSearchRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation

public struct LectureSearchRequest {
  public let semester: Semester
  public let keyword: String
  public let limit: Int
  public let offset: Int

  public init(semester: Semester, keyword: String, limit: Int, offset: Int) {
    self.semester = semester
    self.keyword = keyword
    self.limit = limit
    self.offset = offset
  }
}
