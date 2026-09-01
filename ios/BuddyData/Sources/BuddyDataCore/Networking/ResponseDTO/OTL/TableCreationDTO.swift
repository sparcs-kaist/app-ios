//
//  TableCreationDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 02/03/2026.
//

import Foundation
import BuddyDomain

public struct TableCreationDTO: Codable {
  public let id: Int
}


public extension TableCreationDTO {
  func toModel() -> TableCreation {
    TableCreation(id: id)
  }
}
