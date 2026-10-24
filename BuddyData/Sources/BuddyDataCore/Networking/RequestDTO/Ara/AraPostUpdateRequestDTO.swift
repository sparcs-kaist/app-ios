//
//  AraPostUpdateRequestDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import BuddyDomain

public struct AraPostUpdateRequestDTO: Codable {
  let title: String
  let content: String
  let attachments: [Int]
  let isNSFW: Bool
  let isPolitical: Bool

  enum CodingKeys: String, CodingKey {
    case title
    case content
    case attachments
    case isNSFW = "is_content_sexual"
    case isPolitical = "is_content_social"
  }
}

public extension AraPostUpdateRequestDTO {
  static func fromModel(_ model: AraUpdatePost) -> AraPostUpdateRequestDTO {
    AraPostUpdateRequestDTO(
      title: model.title,
      content: model.content,
      attachments: model.attachmentIDs,
      isNSFW: model.isNSFW,
      isPolitical: model.isPolitical
    )
  }
}
