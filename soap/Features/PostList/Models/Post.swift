//
//  Post.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

struct Post: Identifiable, Hashable {
  let id = UUID()
  let title: String
  let description: String
  let voteCount: Int
  let commentCount: Int
  let author: String
  let createdAt: Date
  let thumbnailURL: URL?
}
