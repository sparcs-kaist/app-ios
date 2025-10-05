//
//  AraBoardGroupDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import BuddyDomain

public struct AraBoardGroupDTO: Codable {
  public let id: Int
  public let koName: String
  public let enName: String
  public let slug: String

  enum CodingKeys: String, CodingKey {
    case id
    case koName = "ko_name"
    case enName = "en_name"
    case slug
  }
}


public extension AraBoardGroupDTO {
  func toModel() -> AraBoardGroup {
    AraBoardGroup(id: id, slug: slug, name: LocalizedString([
      "ko": koName,
      "en": enName
    ]))
  }
}
