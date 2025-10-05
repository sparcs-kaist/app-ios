//
//  ExamTimeDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

public struct ExamTimeDTO: Codable {
  public let description: String
  public let enDescription: String
  public let day: Int
  public let begin: Int
  public let end: Int

  enum CodingKeys: String, CodingKey {
    case description = "str"
    case enDescription = "str_en"
    case day
    case begin
    case end
  }
}


public extension ExamTimeDTO {
  func toModel() -> ExamTime {
    ExamTime(description: LocalizedString([
      "ko": description,
      "en": enDescription
    ]), day: DayType(rawValue: day) ?? .sun, begin: begin, end: end)
  }
}
