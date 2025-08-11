//
//  AraPostComment.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostComment: Identifiable, Hashable, Sendable {
  let id: Int
  let isHidden: Bool?
  let hiddenReason: [String]?
  let overrideHidden: Bool?
  var myVote: Bool?
  var isMine: Bool?
  let content: String?
  let author: AraPostAuthor
  var comments: [AraPostComment]?
  let createdAt: Date
  var upvotes: Int
  var downvotes: Int
  let parentPost: Int?
  let parentComment: Int?
}
