//
//  TaxiChatRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation

struct TaxiChatRequestDTO: Codable {
  let roomId: String
  let type: String
  let content: String?
}

extension TaxiChatRequestDTO {
  static func fromModel(_ model: TaxiChatRequest) -> TaxiChatRequestDTO {
    TaxiChatRequestDTO(roomId: model.roomID, type: model.type.rawValue, content: model.content)
  }
}
