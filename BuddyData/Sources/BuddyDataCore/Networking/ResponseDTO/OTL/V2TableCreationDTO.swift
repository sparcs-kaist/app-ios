//
//  V2TableCreationDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 02/03/2026.
//

import Foundation
import BuddyDomain

public struct V2TableCreationDTO: Codable {
  public let id: Int
}


public extension V2TableCreationDTO {
  func toModel() -> V2TableCreation {
    V2TableCreation(id: id)
  }
}
