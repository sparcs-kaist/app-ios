//
//  LectureExamDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 26/02/2026.
//

import Foundation
import BuddyDomain

public struct LectureExamDTO: Codable {
  public let day: Int
  public let str: String
  public let begin: Int
  public let end: Int
}


public extension LectureExamDTO {
  func toModel() -> LectureExam {
    LectureExam(
      day: DayType(rawValue: day) ?? .sun,
      description: str,
      begin: begin,
      end: end
    )
  }
}
