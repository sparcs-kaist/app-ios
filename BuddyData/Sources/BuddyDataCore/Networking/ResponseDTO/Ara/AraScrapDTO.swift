//
//  AraScrapDTO.swift
//  soap
//
//  Created by 하정우 on 9/28/25.
//

import Foundation

struct AraScrapDTO: Codable {
  let id: Int
  let createdAt: String
  let updatedAt: String
  let deletedAt: String
  let parentArticle: Int
  let scrappedBy: Int
  
  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deletedAt = "deleted_at"
    case parentArticle = "parent_article"
    case scrappedBy = "scrapped_by"
  }
}
