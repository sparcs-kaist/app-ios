//
//  FeedImageDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation

struct FeedImageDTO: Codable {
  let id: String
  let url: String
  let mimeType: String
  let size: Int
  let spoiler: Bool?

  enum CodingKeys: String, CodingKey {
    case id
    case url
    case mimeType = "mime_type"
    case size = "size_bytes"
    case spoiler
  }
}


extension FeedImageDTO {
  func toModel() -> FeedImage? {
    guard let url = URL(string: url) else {
      return nil
    }

    return FeedImage(id: id, url: url, mimeType: mimeType, size: size, spoiler: spoiler)
  }
}
