//
//  LectureExam.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct LectureExam: Hashable, Sendable, Codable {
  public let day: DayType
  public let description: String
  public let begin: Int
  public let end: Int

  public init(day: DayType, description: String, begin: Int, end: Int) {
    self.day = day
    self.description = description
    self.begin = begin
    self.end = end
  }
}
