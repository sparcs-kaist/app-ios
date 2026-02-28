//
//  V2LectureExamDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 26/02/2026.
//

import Foundation
import BuddyDomain

public struct V2LectureExamDTO: Codable {
  public let day: Int
  public let str: String
  public let begin: Int
  public let end: Int
}


public extension V2LectureExamDTO {
  func toModel() -> V2LectureExam {
    V2LectureExam(
      day: DayType(rawValue: day) ?? .sun,
      description: str,
      begin: begin,
      end: end
    )
  }
}
