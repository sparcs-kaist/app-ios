//
//  TaxiCreateRoomRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation

struct TaxiCreateRoomRequestDTO: Codable {
  var name: String
  var from: String
  var to: String
  var time: String
  var maxPartLength: Int
}

extension TaxiCreateRoomRequestDTO {
  static func fromModel(_ model: TaxiCreateRoom) -> TaxiCreateRoomRequestDTO {
    TaxiCreateRoomRequestDTO(
      name: model.title,
      from: model.source.id,
      to: model.destination.id,
      time: model.departureTime.toISO8601,
      maxPartLength: model.capacity
    )
  }
}
