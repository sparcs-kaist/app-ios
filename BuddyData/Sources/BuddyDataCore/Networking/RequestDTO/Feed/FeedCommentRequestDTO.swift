//
//  FeedCommentRequestDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation
import BuddyDomain

public struct FeedCommentRequestDTO: Codable {
  let content: String
  let isAnonymous: Bool
  let imageID: String?

  enum CodingKeys: String, CodingKey {
    case content
    case isAnonymous = "is_anonymous"
    case imageID = "image_id"
  }
}


extension FeedCommentRequestDTO {
  static func fromModel(_ model: FeedCreateComment) -> FeedCommentRequestDTO {
    FeedCommentRequestDTO(content: model.content, isAnonymous: model.isAnonymous, imageID: model.image?.id)
  }
}
