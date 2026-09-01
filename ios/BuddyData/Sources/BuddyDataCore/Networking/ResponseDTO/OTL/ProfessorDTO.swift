//
//  ProfessorDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 26/02/2026.
//

import Foundation
import BuddyDomain

public struct ProfessorDTO: Codable {
  public let id: Int
  public let name: String
}


public extension ProfessorDTO {
  func toModel() -> Professor {
    Professor(id: id, name: name)
  }
}
