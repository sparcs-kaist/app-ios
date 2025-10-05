//
//  FeedImage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

public struct FeedImage: Identifiable, Hashable, Sendable {
  public let id: String
  public let url: URL
  public let mimeType: String
  public let size: Int
  public let spoiler: Bool?

  public init(id: String, url: URL, mimeType: String, size: Int, spoiler: Bool?) {
    self.id = id
    self.url = url
    self.mimeType = mimeType
    self.size = size
    self.spoiler = spoiler
  }
}

