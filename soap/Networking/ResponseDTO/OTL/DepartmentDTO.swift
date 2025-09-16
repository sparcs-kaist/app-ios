//
//  DepartmentDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation

struct DepartmentDTO: Codable {
  let id: Int
  let name: String
  let enName: String
  let code: String

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case enName = "name_en"
    case code
  }
}


extension DepartmentDTO {
  func toModel() -> Department {
    Department(id: id, name: LocalizedString([
      "ko": name,
      "en": enName
    ]), code: code)
  }
}
