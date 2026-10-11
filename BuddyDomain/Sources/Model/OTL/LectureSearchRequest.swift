//
//  LectureSearchRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation

public struct LectureSearchRequest: Sendable {
  public let semester: Semester
  public let keyword: String
  public let filter: LectureSearchFilter
  public let time: LectureTimeFilter
  public let limit: Int
  public let offset: Int

  public init(
    semester: Semester,
    keyword: String,
    filter: LectureSearchFilter = LectureSearchFilter(),
    time: LectureTimeFilter = LectureTimeFilter(),
    limit: Int,
    offset: Int
  ) {
    self.semester = semester
    self.keyword = keyword
    self.filter = filter
    self.time = time
    self.limit = limit
    self.offset = offset
  }
}
