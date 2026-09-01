//
//  AraBookmarkPostDTO.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import Foundation
import BuddyDomain

struct AraBookmarkPostDTO: Codable {
  let posts: AraPostDTO
  
  enum CodingKeys: String, CodingKey {
    case posts = "parent_article"
  }
}

extension AraBookmarkPostDTO {
  func toModel() -> AraPost {
    posts.toModel()
  }
}
