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
  let isArrived: Bool?
  let hasCarrier: Bool

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case name
    case nickname
    case profileImageURL = "profileImageUrl"
    case withdraw
    case badge
    case isSettlement
    case readAt
    case isArrived
    case hasCarrier
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
      isArrived: isArrived ?? false,
      hasCarrier: hasCarrier,
      readAt: readAt.toDate() ?? Date()
    )
  }
}
