//
//  FeedPostPhotoItem.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public struct FeedPostPhotoItem: Identifiable, Hashable, Sendable {
  public let id: String
  public let image: PlatformImage
  public var spoiler: Bool
  public var description: String

  public init(id: String, image: PlatformImage, spoiler: Bool, description: String) {
    self.id = id
    self.image = image
    self.spoiler = spoiler
    self.description = description
  }
}
