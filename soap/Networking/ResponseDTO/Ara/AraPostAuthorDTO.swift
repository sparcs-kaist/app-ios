//
//  AraPostAuthorDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostAuthorDTO: Codable {
  let id: Int
  let username: String
  let profile: AraPostAuthorProfileDTO
  let isBlocked: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case profile
    case isBlocked = "is_blocked"
  }
}


extension AraPostAuthorDTO {
  func toModel() -> AraPostAuthor {
    AraPostAuthor(id: id, username: username, profile: profile.toModel(), isBlocked: isBlocked)
  }
}
