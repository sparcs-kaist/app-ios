//
//  AraMeDTO.swift
//  soap
//
//  Created by 하정우 on 8/19/25.
//

import Foundation

struct AraMeResponseDTO: Codable {
  let allowNSFW: Bool
  let allowPolitical: Bool
  
  enum CodingKeys: String, CodingKey {
    case allowNSFW = "see_sexual"
    case allowPolitical = "see_social"
  }
}

extension AraMeResponseDTO {
  func toModel() -> AraMe {
    AraMe(allowNSFW: allowNSFW, allowPolitical: allowPolitical)
  }
}
