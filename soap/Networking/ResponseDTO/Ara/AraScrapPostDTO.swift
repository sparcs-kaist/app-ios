//
//  AraScrapPostDTO.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import Foundation

struct AraScrapPostDTO: Codable {
  let posts: AraPostDTO
  
  enum CodingKeys: String, CodingKey {
    case posts = "parent_article"
  }
}

extension AraScrapPostDTO {
  func toModel() -> AraPost {
    posts.toModel()
  }
}
