//
//  FeedProfileImageDTO.swift
//  BuddyData
//
//  Created by 하정우 on 2/21/26.
//

import Foundation

public struct FeedProfileImageDTO: Codable {
  public let url: String
  
  enum CodingKeys: String, CodingKey {
    case url = "profile_image_url"
  }
}
