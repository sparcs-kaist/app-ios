//
//  AraAttachment.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

struct AraAttachment: Identifiable, Hashable {
  let id: Int
  let file: URL?
  let size: Int
  let mimeType: String
  let createdAt: Date
}
