//
//  CourseSearchRequest.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct CourseSearchRequest: Codable {
  public let keyword: String
  public let limit: Int
  public let offset: Int

  public init(keyword: String, limit: Int, offset: Int) {
    self.keyword = keyword
    self.limit = limit
    self.offset = offset
  }
}
