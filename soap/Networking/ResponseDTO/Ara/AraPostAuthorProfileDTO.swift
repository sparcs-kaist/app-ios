//
//  AraPostAuthorProfileDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostAuthorProfileDTO: Codable {
  let id: Int
  let profilePictureURL: String
  let nickname: String
  let isOfficial: Bool
  let isSchoolAdmin: Bool

  enum CodingKeys: String, CodingKey {
    case id = "user"
    case profilePictureURL = "picture"
    case nickname
    case isOfficial = "is_official"
    case isSchoolAdmin = "is_school_admin"
  }
}


extension AraPostAuthorProfileDTO {
  func toModel() -> AraPostAuthorProfile {
    AraPostAuthorProfile(
      id: id,
      profilePictureURL: URL(string: profilePictureURL),
      nickname: nickname,
      isOfficial: isOfficial,
      isSchoolAdmin: isSchoolAdmin
    )
  }
}
