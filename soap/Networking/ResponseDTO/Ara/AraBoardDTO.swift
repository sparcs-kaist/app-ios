//
//  AraBoardDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

struct AraBoardDTO: Codable {
  let id: Int
  let slug: String
  let koName: String
  let enName: String
  let isReadOnly: Bool
  let group: AraBoardGroupDTO
  let topics: [AraBoardTopicDTO]
  let userReadable: Bool
  let userWritable: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case slug
    case koName = "ko_name"
    case enName = "en_name"
    case isReadOnly = "is_readonly"
    case group
    case topics
    case userReadable = "user_readable"
    case userWritable = "user_writable"
  }
}


extension AraBoardDTO {
  func toModel() -> AraBoard {
    AraBoard(
      id: id,
      slug: slug,
      name: LocalizedString([
        "ko": koName,
        "en": enName
      ]),
      group: group.toModel(),
      topics: topics.compactMap { $0.toModel() },
      isReadOnly: isReadOnly,
      userReadable: userReadable,
      userWritable: userWritable
    )
  }
}
