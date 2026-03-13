//
//  DepartmentDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

public struct DepartmentDTO: Codable {
  public let id: Int
  public let name: String
}


public extension DepartmentDTO {
  func toModel() -> Department {
    Department(id: id, name: name)
  }
}
