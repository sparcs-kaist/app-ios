//
//  TaxiUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation
import BuddyDomain

struct TaxiParticipantDTO: Codable {
  let id: String
  let name: String
  let nickname: String
  let profileImageURL: String
  let withdraw: Bool
  let badge: Bool?
  let isSettlement: String?
  let readAt: String

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case name
    case nickname
    case profileImageURL = "profileImageUrl"
    case withdraw
    case badge
    case isSettlement
    case readAt
  }
}


extension TaxiParticipantDTO {
  func toModel() -> TaxiParticipant {
    TaxiParticipant(
      id: id,
      name: name,
      nickname: nickname,
      profileImageURL: URL(string: profileImageURL),
      withdraw: withdraw,
      badge: badge ?? false, // treat as false when nil
      isSettlement: isSettlement != nil ? TaxiParticipant
        .SettlementType(rawValue: isSettlement!) : nil,
      readAt: readAt.toDate() ?? Date()
    )
  }
}
