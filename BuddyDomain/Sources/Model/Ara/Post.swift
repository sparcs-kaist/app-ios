//
//  Post.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

public struct Post: Identifiable, Hashable {
  public let id = UUID()
  public let title: String
  public let description: String
  public let voteCount: Int
  public let commentCount: Int
  public let author: String
  public let createdAt: Date
  public let thumbnailURL: URL?

  public init(
    title: String,
    description: String,
    voteCount: Int,
    commentCount: Int,
    author: String,
    createdAt: Date,
    thumbnailURL: URL?
  ) {
    self.title = title
    self.description = description
    self.voteCount = voteCount
    self.commentCount = commentCount
    self.author = author
    self.createdAt = createdAt
    self.thumbnailURL = thumbnailURL
  }
}
