//
//  DepartmentOptionDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation
import BuddyDomain

struct DepartmentOptionListDTO: Codable {
  let departments: [DepartmentOptionDTO]
}

struct DepartmentOptionDTO: Codable {
  let id: Int
  let name: String
  let code: String
}


extension DepartmentOptionDTO {
  func toModel() -> DepartmentOption {
    DepartmentOption(id: id, name: name, code: code)
  }
}
