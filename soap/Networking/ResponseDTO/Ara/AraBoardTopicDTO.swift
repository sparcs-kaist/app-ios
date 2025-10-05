//
//  AraBoardTopicDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import BuddyDomain

struct AraBoardTopicDTO: Codable {
  let id: Int
  let koName: String
  let enName: String
  let slug: String

  enum CodingKeys: String, CodingKey {
    case id
    case koName = "ko_name"
    case enName = "en_name"
    case slug
  }
}


extension AraBoardTopicDTO {
  func toModel() -> AraBoardTopic {
    AraBoardTopic(id: id, slug: slug, name: LocalizedString([
      "ko": koName,
      "en": enName
    ]))
  }
}
