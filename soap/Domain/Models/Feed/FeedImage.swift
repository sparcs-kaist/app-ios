//
//  FeedImage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

struct FeedImage: Identifiable, Hashable {
  let id: String
  let url: URL
  let mimeType: String
  let size: Int
  let spoiler: Bool?
}

