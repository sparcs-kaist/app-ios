//
//  FeedImageDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import BuddyDomain

public struct FeedImageDTO: Codable {
  public let id: String
  public let url: String
  public let mimeType: String
  public let size: Int
  public let spoiler: Bool?

  enum CodingKeys: String, CodingKey {
    case id
    case url
    case mimeType = "mime_type"
    case size = "size_bytes"
    case spoiler
  }
}


public extension FeedImageDTO {
  func toModel() -> FeedImage? {
    guard let url = URL(string: url) else {
      return nil
    }

    return FeedImage(id: id, url: url, mimeType: mimeType, size: size, spoiler: spoiler)
  }
}
