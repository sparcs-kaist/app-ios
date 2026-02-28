//
//  V2ProfessorDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 26/02/2026.
//

import Foundation
import BuddyDomain

public struct V2ProfessorDTO: Codable {
  public let id: Int
  public let name: String
}


public extension V2ProfessorDTO {
  func toModel() -> V2Professor {
    V2Professor(id: id, name: name)
  }
}
