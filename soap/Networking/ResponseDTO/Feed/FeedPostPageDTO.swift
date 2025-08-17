//
//  FeedPostPageDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation

struct FeedPostPageDTO: Codable {
  let items: [FeedPostDTO]
  let nextCursor: String?
  let hasNext: Bool

  enum CodingKeys: String, CodingKey {
    case items
    case nextCursor = "next_cursor"
    case hasNext = "has_next"
  }
}

extension FeedPostPageDTO {
  func toModel() -> FeedPostPage {
    FeedPostPage(items: items.compactMap { $0.toModel() }, nextCursor: nextCursor, hasNext: hasNext)
  }
}
