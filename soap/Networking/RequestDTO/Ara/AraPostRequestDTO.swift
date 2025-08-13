//
//  AraPostRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

struct AraPostRequestDTO: Codable {
  let title: String
  let content: String
  let attachments: [Int]
  let topic: Int?
  let isNSFW: Bool
  let isPolitical: Bool
  let nicknameType: String
  let board: Int

  enum CodingKeys: String, CodingKey {
    case title
    case content
    case attachments
    case topic = "parent_topic"
    case isNSFW = "is_content_sexual"
    case isPolitical = "is_content_social"
    case nicknameType = "name_type"
    case board = "parent_board"
  }
}

extension AraPostRequestDTO {
  static func fromModel(_ model: AraCreatePost) -> AraPostRequestDTO {
    AraPostRequestDTO(
      title: model.title,
      content: model.content.toHTMLParagraphs(),
      attachments: model.attachments.compactMap { $0.id },
      topic: model.topic?.id,
      isNSFW: model.isNSFW,
      isPolitical: model.isPolitical,
      nicknameType: model.nicknameType.rawValue,
      board: model.board.id
    )
  }
}
