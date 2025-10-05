//
//  FeedPostPage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

public struct FeedPostPage: Sendable {
  public let items: [FeedPost]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(items: [FeedPost], nextCursor: String?, hasNext: Bool) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}

