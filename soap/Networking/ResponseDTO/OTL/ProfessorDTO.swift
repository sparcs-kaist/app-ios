//
//  ProfessorDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation

struct ProfessorDTO: Codable {
  let id: Int
  let name: String
  let enName: String
  let reviewTotalWeight: Double

  enum CodingKeys: String, CodingKey {
    case id = "professor_id"
    case name
    case enName
    case reviewTotalWeight = "review_total_weight"
  }
}
