//
//  TaxiNoticeDTO.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation

struct TaxiNoticeDTO: Decodable {
  struct NoticeElement: Decodable {
    let id: String
    let title: String
    let notionURL: String
    let isPinned: Bool
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
      case id = "_id"
      case title, createdAt, updatedAt
      case notionURL = "notion_url"
      case isPinned = "is_pinned"
      case isActive = "is_active"
    }
  }
  
  let notices: [NoticeElement]
}
