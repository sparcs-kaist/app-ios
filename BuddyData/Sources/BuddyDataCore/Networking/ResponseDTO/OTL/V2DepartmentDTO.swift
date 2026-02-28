//
//  V2DepartmentDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

public struct V2DepartmentDTO: Codable {
  public let id: Int
  public let name: String
}


public extension V2DepartmentDTO {
  func toModel() -> V2Department {
    V2Department(id: id, name: name)
  }
}
