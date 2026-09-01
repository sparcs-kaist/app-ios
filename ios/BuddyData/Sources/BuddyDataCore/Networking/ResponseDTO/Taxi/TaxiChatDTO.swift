//
//  TaxiChatDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Foundation
import BuddyDomain

public struct TaxiChatDTO: Codable {
  public let roomID: String
  public let type: String
  public let authorID: String?
  public let authorName: String?
  public let authorProfileURL: String?
  public let authorIsWithdrew: Bool?
  public let content: String
  public let time: String
  public let isValid: Bool
  public let inOutNames: [String]?

  public enum CodingKeys: String, CodingKey {
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

public extension TaxiChatDTO {
  func toModel() -> TaxiChat {
    TaxiChat(
      roomID: roomID,
      type: TaxiChat.ChatType(rawValue: type) ?? .text,
      authorID: authorID,
      authorName: authorName,
      authorProfileURL: URL(string: authorProfileURL ?? ""),
      authorIsWithdrew: authorIsWithdrew,
      content: content.trimmingCharacters(in: .whitespacesAndNewlines),
      time: time.toDate() ?? Date(),
      isValid: isValid,
      inOutNames: inOutNames
    )
  }
}
