//
//  FeedUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import Foundation
import BuddyDomain

struct FeedUserDTO: Codable {
  let id: String
  let nickname: String
  let profileImageURL: String
  let karma: Int

  enum CodingKeys: String, CodingKey {
    case id
    case nickname
    case profileImageURL = "profile_image_url"
    case karma = "karma_total"
  }
}


extension FeedUserDTO {
  func toModel() -> FeedUser {
    FeedUser(
      id: id,
      nickname: nickname,
      profileImageURL: URL(string: profileImageURL),
      karma: karma
    )
  }
}
