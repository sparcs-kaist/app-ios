//
//  AraPostAttachmentDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation
import BuddyDomain

struct AraPostAttachmentDTO: Codable {
  let id: Int
  let createdAt: String
  let file: String
  let size: Int
  let mimeType: String

  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case file
    case size
    case mimeType = "mimetype"
  }
}


extension AraPostAttachmentDTO {
  func toModel() -> AraPostAttachment {
    AraPostAttachment(
      id: id,
      createdAt: createdAt.toDate() ?? Date(),
      file: URL(string: file),
      filename: URL(string: file)?.lastPathComponent ?? "Untitled",
      size: size,
      mimeType: mimeType
    )
  }
}
