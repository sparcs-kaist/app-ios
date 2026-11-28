//
//  NearbyRelayResponseDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import BuddyDomain

public struct NearbyPresenceExpiryDTO: Decodable {
  public let expiresAt: String
}

public struct NearbyPresenceItemDTO: Decodable {
  public let lookupId: String
  public let blob: String
  public let expiresAt: String
}

public struct NearbyBatchGetResponseDTO: Decodable {
  public let items: [NearbyPresenceItemDTO]
}

public struct NearbyRelayMessageDTO: Decodable {
  public let id: String
  public let header: String
  public let body: String
  public let createdAt: String
}

public struct NearbyMessagesPageDTO: Decodable {
  public let messages: [NearbyRelayMessageDTO]
  public let cursor: String
}

public extension NearbyMessagesPageDTO {
  /// Drops any message whose fields aren't valid base64url rather than failing
  /// the whole page; the use case would discard it anyway.
  func toModel() -> RelayMessagesPage {
    RelayMessagesPage(
      messages: messages.compactMap { message in
        guard let header = Data(base64URLEncoded: message.header),
              let body = Data(base64URLEncoded: message.body) else { return nil }
        return RelayMessage(id: message.id, header: header, body: body)
      },
      cursor: cursor
    )
  }
}
