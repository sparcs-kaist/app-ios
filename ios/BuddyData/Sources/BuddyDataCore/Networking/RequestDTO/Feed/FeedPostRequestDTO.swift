//
//  FeedPostRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import BuddyDomain

public struct FeedPostRequestDTO: Codable {
  let content: String
  let isAnonymous: Bool
  let imageIDs: [String]

  enum CodingKeys: String, CodingKey {
    case content
    case isAnonymous = "is_anonymous"
    case imageIDs = "image_ids"
  }
}


extension FeedPostRequestDTO {
  static func fromModel(_ model: FeedCreatePost) -> FeedPostRequestDTO {
    FeedPostRequestDTO(content: model.content, isAnonymous: model.isAnonymous, imageIDs: model.images.compactMap { $0.id })
  }
}
