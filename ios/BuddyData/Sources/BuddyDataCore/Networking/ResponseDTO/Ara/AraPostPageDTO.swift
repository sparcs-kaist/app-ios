//
//  AraPostPageDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation
import BuddyDomain

public struct AraPostPageDTO: Codable {
  let pages: Int
  let items: Int
  let currentPage: Int
  let results: [AraPostDTO]

  enum CodingKeys: String, CodingKey {
    case pages = "num_pages"
    case items = "num_items"
    case currentPage = "current"
    case results
  }
}


public extension AraPostPageDTO {
  func toModel() -> AraPostPage {
    AraPostPage(pages: pages, items: items, currentPage: currentPage, results: results.compactMap { $0.toModel() })
  }
}
