//
//  TaxiMyRoomsResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

struct TaxiMyRoomsResponseDTO: Codable {
  let onGoing: [TaxiRoomDTO]
  let done: [TaxiRoomDTO]

  enum CodingKeys: String, CodingKey {
    case onGoing = "ongoing"
    case done
  }
}
