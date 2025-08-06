//
//  AraPostAuthorProfileDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostAuthorProfileDTO: Codable {
  let id: String
  let profilePictureURL: String?
  let nickname: String
  let isOfficial: Bool?
  let isSchoolAdmin: Bool?

  enum CodingKeys: String, CodingKey {
    case id = "user"
    case profilePictureURL = "picture"
    case nickname
    case isOfficial = "is_official"
    case isSchoolAdmin = "is_school_admin"
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
    
    profilePictureURL = try container.decodeIfPresent(String.self, forKey: .profilePictureURL)
    nickname = try container.decode(String.self, forKey: .nickname)
    isOfficial = try container.decodeIfPresent(Bool.self, forKey: .isOfficial)
    isSchoolAdmin = try container.decodeIfPresent(Bool.self, forKey: .isSchoolAdmin)
  }
}


extension AraPostAuthorProfileDTO {
  func toModel() -> AraPostAuthorProfile {
    AraPostAuthorProfile(
      id: id,
      profilePictureURL: profilePictureURL != nil ? URL(string: profilePictureURL!) : nil,
      nickname: nickname,
      isOfficial: isOfficial,
      isSchoolAdmin: isSchoolAdmin
    )
  }
}
