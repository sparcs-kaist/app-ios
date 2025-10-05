//
//  ProfessorDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

public struct ProfessorDTO: Codable {
  public let id: Int
  public let name: String
  public let enName: String
  public let reviewTotalWeight: Double

  enum CodingKeys: String, CodingKey {
    case id = "professor_id"
    case name
    case enName = "name_en"
    case reviewTotalWeight = "review_total_weight"
  }
}


public extension ProfessorDTO {
  func toModel() -> Professor {
    Professor(id: id, name: LocalizedString([
      "ko": name,
      "en": enName
    ]), reviewTotalWeight: reviewTotalWeight)
  }
}
