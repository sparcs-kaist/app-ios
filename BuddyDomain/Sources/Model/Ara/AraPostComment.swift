//
//  AraPostComment.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPostComment: Identifiable, Hashable, Sendable {
  public let id: Int
  public let isHidden: Bool?
  public let hiddenReason: [String]?
  public let overrideHidden: Bool?
  public var myVote: Bool?
  public var isMine: Bool?
  public var content: String?
  public let author: AraPostAuthor
  public var comments: [AraPostComment]
  public let createdAt: Date
  public var upvotes: Int
  public var downvotes: Int
  public let parentPost: Int?
  public let parentComment: Int?

  public init(
    id: Int,
    isHidden: Bool?,
    hiddenReason: [String]?,
    overrideHidden: Bool?,
    myVote: Bool? = nil,
    isMine: Bool? = nil,
    content: String? = nil,
    author: AraPostAuthor,
    comments: [AraPostComment],
    createdAt: Date,
    upvotes: Int,
    downvotes: Int,
    parentPost: Int?,
    parentComment: Int?
  ) {
    self.id = id
    self.isHidden = isHidden
    self.hiddenReason = hiddenReason
    self.overrideHidden = overrideHidden
    self.myVote = myVote
    self.isMine = isMine
    self.content = content
    self.author = author
    self.comments = comments
    self.createdAt = createdAt
    self.upvotes = upvotes
    self.downvotes = downvotes
    self.parentPost = parentPost
    self.parentComment = parentComment
  }
}
