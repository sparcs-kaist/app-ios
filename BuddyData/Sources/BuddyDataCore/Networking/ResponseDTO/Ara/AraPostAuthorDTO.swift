//
//  AraPostAuthorDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation
import BuddyDomain

struct AraPostAuthorDTO: Codable {
  let id: String
  let username: String
  let profile: AraPostAuthorProfileDTO
  let isBlocked: Bool?

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case profile
    case isBlocked = "is_blocked"
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    // id could be Int or String.
    if let intId = try? container.decode(Int.self, forKey: .id) {
      id = String(intId)
    } else if let stringId = try? container.decode(String.self, forKey: .id) {
      id = stringId
    } else {
      throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String for id field"))
    }
    
    username = try container.decode(String.self, forKey: .username)
    profile = try container.decode(AraPostAuthorProfileDTO.self, forKey: .profile)
    isBlocked = try container.decodeIfPresent(Bool.self, forKey: .isBlocked)
  }
}


extension AraPostAuthorDTO {
  func toModel() -> AraPostAuthor {
    AraPostAuthor(id: id, username: username, profile: profile.toModel(), isBlocked: isBlocked)
  }
}
