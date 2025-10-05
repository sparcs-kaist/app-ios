//
//  FeedCreateComment.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation

public struct FeedCreateComment: Sendable {
  public let content: String
  public let isAnonymous: Bool
  public let image: FeedImage?

  public init(content: String, isAnonymous: Bool, image: FeedImage?) {
    self.content = content
    self.isAnonymous = isAnonymous
    self.image = image
  }
}
