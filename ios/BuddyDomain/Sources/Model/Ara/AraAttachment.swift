//
//  AraAttachment.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

public struct AraAttachment: Identifiable, Hashable, Sendable {
  public let id: Int
  public let file: URL?
  public let size: Int
  public let mimeType: String
  public let createdAt: Date

  public init(id: Int, file: URL?, size: Int, mimeType: String, createdAt: Date) {
    self.id = id
    self.file = file
    self.size = size
    self.mimeType = mimeType
    self.createdAt = createdAt
  }
}
