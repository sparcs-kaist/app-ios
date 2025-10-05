//
//  FeedCreatePost.swift
//  soap
//
//  Created by Soongyu Kwon on 21/08/2025.
//

import Foundation

public struct FeedCreatePost: Sendable {
  public let content: String
  public let isAnonymous: Bool
  public let images: [FeedImage]

  public init(content: String, isAnonymous: Bool, images: [FeedImage]) {
    self.content = content
    self.isAnonymous = isAnonymous
    self.images = images
  }
}
