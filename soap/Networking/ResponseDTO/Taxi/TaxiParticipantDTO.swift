//
//  TaxiUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation

struct TaxiParticipantDTO: Codable {
  let id: String
  let name: String
  let nickname: String
  let profileImageURL: String
  let withdraw: Bool
  let readAt: String

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case name
    case nickname
    case profileImageURL = "profileImageUrl"
    case withdraw
    case readAt
  }
}


extension TaxiParticipantDTO {
  func toModel() -> TaxiParticipant {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let readAtInFormat = formatter.date(from: readAt) ?? Date()

    return TaxiParticipant(
      id: id,
      name: name,
      nickname: nickname,
      profileImageURL: URL(string: profileImageURL),
      withdraw: withdraw,
      readAt: readAtInFormat
    )
  }
}
