//
//  TaxiRoomDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation

struct TaxiRoomDTO: Codable {
  let id: String
  let name: String
  let from: TaxiLocationDTO
  let to: TaxiLocationDTO
  let time: String
  let participants: [TaxiParticipantDTO]
  let madeAt: String
  let maxParticipants: Int
  let isDeparted: Bool

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case name
    case from
    case to
    case time
    case participants = "part"
    case madeAt = "madeat"
    case maxParticipants = "maxPartLength"
    case isDeparted
  }
}


extension TaxiRoomDTO {
  func toModel() -> TaxiRoom {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let timeInFormat = formatter.date(from: time) ?? Date()
    let madeAtInFormat = formatter.date(from: madeAt) ?? Date()

    return TaxiRoom(
      id: id,
      title: name,
      source: from.toModel(),
      destination: to.toModel(),
      departAt: timeInFormat,
      participants: participants.map { $0.toModel() },
      madeAt: madeAtInFormat,
      capacity: maxParticipants,
      isDeparted: isDeparted
    )
  }
}
