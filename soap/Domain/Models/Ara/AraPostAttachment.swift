//
//  AraPostAttachment.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostAttachment: Identifiable, Hashable {
  let id: Int
  let createdAt: Date
  let file: URL?
  let filename: String
  let size: Int
  let mimeType: String
}
