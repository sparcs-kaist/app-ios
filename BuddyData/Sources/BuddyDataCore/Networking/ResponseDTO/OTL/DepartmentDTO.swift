//
//  DepartmentDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation
import BuddyDomain

public struct DepartmentDTO: Codable {
  public let id: Int
  public let name: String
  public let enName: String
  public let code: String

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case enName = "name_en"
    case code
  }
}


public extension DepartmentDTO {
  func toModel() -> Department {
    Department(id: id, name: LocalizedString([
      "ko": name,
      "en": enName
    ]), code: code)
  }
}
