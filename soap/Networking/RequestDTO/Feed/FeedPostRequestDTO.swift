//
//  FeedPostRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation

struct FeedPostRequestDTO: Codable {
  let content: String
  let isAnonymous: Bool
  let imageIDs: [String]

  enum CodingKeys: String, CodingKey {
    case content
    case isAnonymous = "is_anonymous"
    case imageIDs = "image_ids"
  }
}
