//
//  AraAttachmentDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation
import BuddyDomain

public struct AraAttachmentDTO: Codable {
  let id: Int
  let file: String
  let size: Int
  let mimeType: String
  let createdAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case file
    case size
    case mimeType = "mimetype"
    case createdAt = "created_at"
  }
}


public extension AraAttachmentDTO {
  func toModel() -> AraAttachment {
    AraAttachment(
      id: id,
      file: URL(string: file),
      size: size,
      mimeType: mimeType,
      createdAt: createdAt.toDate() ?? Date()
    )
  }
}
