//
//  TaxiLocationSrhotDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation

struct TaxiLocationShortDTO: Codable {
  let id: String
  let enName: String
  let koName: String
  let latitude: Double
  let longitude: Double

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case enName
    case koName
    case latitude
    case longitude
  }
}


extension TaxiLocationShortDTO {
  func toModel() -> TaxiLocationShort {
    TaxiLocationShort(id: id, title: LocalizedString([
      "ko": koName,
      "en": enName
    ]), latitude: latitude, longitude: longitude)
  }
}
