//
//  AraMeDTO.swift
//  soap
//
//  Created by 하정우 on 8/19/25.
//

import Foundation

struct AraMeResponseDTO: Codable {
  let id: Int
  let nickname: String
  let nicknameUpdatedAt: String
  let allowNSFW: Bool
  let allowPolitical: Bool
  
  enum CodingKeys: String, CodingKey {
    case id = "user"
    case nickname
    case nicknameUpdatedAt = "nickname_updated_at"
    case allowNSFW = "see_sexual"
    case allowPolitical = "see_social"
  }
}

extension AraMeResponseDTO {
  func toModel() -> AraMe {
    AraMe(id: id, nickname: nickname, nicknameUpdatedAt: nicknameUpdatedAt.toDate(), allowNSFW: allowNSFW, allowPolitical: allowPolitical)
  }
}
