//
//  TaxiLocationDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import BuddyDomain

struct TaxiLocationDTO: Codable {
  let id: String
  let enName: String
  let koName: String
  let priority: Double?
  let isValid: Bool?
  let latitude: Double
  let longitude: Double

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case enName
    case koName
    case priority
    case isValid
    case latitude
    case longitude
  }
}

extension TaxiLocationDTO {
  func toModel() -> TaxiLocation {
    TaxiLocation(id: id, title: LocalizedString([
      "ko": koName,
      "en": enName
    ]), priority: priority, latitude: latitude, longitude: longitude)
  }
}
