//
//  TaxiChatDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Foundation

struct TaxiChatDTO: Codable {
  let roomID: String
  let type: String
  let authorID: String?
  let authorName: String?
  let authorProfileURL: String?
  let authorIsWithdrew: Bool?
  let content: String
  let time: String
  let isValid: Bool
  let inOutNames: [String]?

  enum CodingKeys: String, CodingKey {
    case roomID = "roomId"
    case type
    case authorID = "authorId"
    case authorName
    case authorProfileURL = "authorProfileUrl"
    case authorIsWithdrew
    case content
    case time
    case isValid
    case inOutNames
  }
}

extension TaxiChatDTO {
  func toModel() -> TaxiChat {
    TaxiChat(
      roomID: roomID,
      type: TaxiChat.ChatType(rawValue: type) ?? .text,
      authorID: authorID,
      authorName: authorName,
      authorProfileURL: URL(string: authorProfileURL ?? ""),
      authorIsWithdrew: authorIsWithdrew,
      content: content,
      time: time.toDate() ?? Date(),
      isValid: isValid,
      inOutNames: inOutNames
    )
  }
}
