//
//  AraBoardDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import BuddyDomain

public struct AraBoardDTO: Codable {
  public let id: Int
  public let slug: String
  public let koName: String
  public let enName: String
  public let isReadOnly: Bool
  public let group: AraBoardGroupDTO
  public let topics: [AraBoardTopicDTO]?
  public let userReadable: Bool?
  public let userWritable: Bool?

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


public extension AraBoardDTO {
  func toModel() -> AraBoard {
    AraBoard(
      id: id,
      slug: slug,
      name: LocalizedString([
        "ko": koName,
        "en": enName
      ]),
      group: group.toModel(),
      topics: topics?.compactMap { $0.toModel() },
      isReadOnly: isReadOnly,
      userReadable: userReadable,
      userWritable: userWritable
    )
  }
}
