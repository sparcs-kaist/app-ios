//
//  AraPostComment.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostComment: Identifiable, Hashable, Sendable {
  let id: Int
  let isHidden: Bool
  let hiddenReason: [String]
  let overrideHidden: Bool?
  let myVote: Bool?
  let isMine: Bool
  let content: String
  let author: AraPostAuthor
  let comments: [AraPostComment]?
  let createdAt: Date
  let upvotes: Int
  let downvotes: Int
  let parentPost: Int?
  let parentComment: Int?
}

