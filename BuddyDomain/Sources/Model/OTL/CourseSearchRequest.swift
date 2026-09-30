//
//  CourseSearchRequest.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct CourseSearchRequest: Sendable {
  public let keyword: String
  public let filter: LectureSearchFilter
  public let period: CourseSearchPeriod?
  public let limit: Int
  public let offset: Int

  public init(
    keyword: String,
    filter: LectureSearchFilter = LectureSearchFilter(),
    period: CourseSearchPeriod? = nil,
    limit: Int,
    offset: Int
  ) {
    self.keyword = keyword
    self.filter = filter
    self.period = period
    self.limit = limit
    self.offset = offset
  }
}

/// Limits a course search to courses that were offered recently. The raw value is the number of
/// years to look back.
public enum CourseSearchPeriod: Int, CaseIterable, Identifiable, Sendable {
  case oneYear = 1
  case twoYears = 2
  case threeYears = 3

  public var id: Int { rawValue }
}
