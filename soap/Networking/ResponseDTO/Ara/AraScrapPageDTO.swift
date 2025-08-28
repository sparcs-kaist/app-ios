//
//  AraScrapPageDTO.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import Foundation

struct AraScrapPageDTO: Codable {
  let pages: Int
  let items: Int
  let currentPage: Int
  let results: [AraScrapPostDTO]

  enum CodingKeys: String, CodingKey {
    case pages = "num_pages"
    case items = "num_items"
    case currentPage = "current"
    case results
  }
}


extension AraScrapPageDTO {
  func toModel() -> AraPostPage {
    AraPostPage(pages: pages, items: items, currentPage: currentPage, results: results.compactMap { $0.toModel() })
  }
}
