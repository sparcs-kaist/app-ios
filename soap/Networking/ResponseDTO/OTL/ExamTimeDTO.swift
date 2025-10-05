//
//  ExamTimeDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

struct ExamTimeDTO: Codable {
  let description: String
  let enDescription: String
  let day: Int
  let begin: Int
  let end: Int

  enum CodingKeys: String, CodingKey {
    case description = "str"
    case enDescription = "str_en"
    case day
    case begin
    case end
  }
}


extension ExamTimeDTO {
  func toModel() -> ExamTime {
    ExamTime(description: LocalizedString([
      "ko": description,
      "en": enDescription
    ]), day: DayType(rawValue: day) ?? .sun, begin: begin, end: end)
  }
}
