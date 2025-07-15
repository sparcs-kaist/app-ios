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
  let settlementTotal: Int?
  let isDeparted: Bool
  let isOver: Bool?

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case name
    case from
    case to
    case time
    case participants = "part"
    case madeAt = "madeat"
    case maxParticipants = "maxPartLength"
    case settlementTotal
    case isDeparted
    case isOver
  }
}


extension TaxiRoomDTO {
  func toModel() -> TaxiRoom {
    TaxiRoom(
      id: id,
      title: name,
      source: from.toModel(),
      destination: to.toModel(),
      departAt: time.toDate() ?? Date(),
      participants: participants.map { $0.toModel() },
      madeAt: madeAt.toDate() ?? Date(),
      capacity: maxParticipants,
      settlementTotal: settlementTotal,
      isDeparted: isDeparted,
      isOver: isOver
    )
  }
}
