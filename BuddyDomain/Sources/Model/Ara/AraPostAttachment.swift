//
//  AraPostAttachment.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPostAttachment: Identifiable, Hashable, Sendable {
  public let id: Int
  public let createdAt: Date
  public let file: URL?
  public let filename: String
  public let size: Int
  public let mimeType: String

  public init(id: Int, createdAt: Date, file: URL?, filename: String, size: Int, mimeType: String) {
    self.id = id
    self.createdAt = createdAt
    self.file = file
    self.filename = filename
    self.size = size
    self.mimeType = mimeType
  }
}
