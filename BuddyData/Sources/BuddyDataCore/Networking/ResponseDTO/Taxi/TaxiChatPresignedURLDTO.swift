//
//  TaxiChatPresignedURLDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 28/07/2025.
//

import Foundation
import BuddyDomain

public struct TaxiChatPresignedURLDTO: Codable {
  let id: String
  let url: String
  let fields: [String: String]
}

public extension TaxiChatPresignedURLDTO {
  func toModel() -> TaxiChatPresignedURL {
    TaxiChatPresignedURL(id: id, url: url, fields: fields)
  }

  static func fromModel(model: TaxiChatPresignedURL) -> TaxiChatPresignedURLDTO {
    TaxiChatPresignedURLDTO(id: model.id, url: model.url, fields: model.fields)
  }
}
