//
//  AraBlockDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 26/10/2026.
//

import Foundation
import BuddyDomain

struct AraBlockPageDTO: Decodable {
  let numPages: Int
  let current: Int
  let results: [AraBlockDTO]

  enum CodingKeys: String, CodingKey {
    case numPages = "num_pages"
    case current
    case results
  }
}

/// One block: the user blocked, with their public profile.
struct AraBlockDTO: Decodable {
  let user: AraPostAuthorDTO
}

extension AraBlockDTO {
  /// `nil` if Ara sent an ID that isn't an account number, which unblocking couldn't use.
  func toModel() -> AraBlockedUser? {
    guard let id = Int(user.id) else { return nil }
    let author = user.toModel()
    return AraBlockedUser(id: id, nickname: author.profile.nickname, profilePictureURL: author.profile.profilePictureURL)
  }
}
