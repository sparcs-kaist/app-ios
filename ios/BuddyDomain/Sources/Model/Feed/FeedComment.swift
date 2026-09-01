//
//  FeedComment.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation

public struct FeedComment: Identifiable, Hashable, Sendable {
  public let id: String
  public let postID: String
  public let parentCommentID: String?
  public let content: String
  public var isDeleted: Bool
  public let isAnonymous: Bool
  public let isKaistIP: Bool
  public let authorName: String
  public let isAuthor: Bool
  public let isMyComment: Bool
  public let profileImageURL: URL?
  public let createdAt: Date
  public var upvotes: Int
  public var downvotes: Int
  public var myVote: FeedVoteType?
  public let image: FeedImage?
  public var replyCount: Int
  public var replies: [FeedComment]

  public init(
    id: String,
    postID: String,
    parentCommentID: String?,
    content: String,
    isDeleted: Bool,
    isAnonymous: Bool,
    isKaistIP: Bool,
    authorName: String,
    isAuthor: Bool,
    isMyComment: Bool,
    profileImageURL: URL?,
    createdAt: Date,
    upvotes: Int,
    downvotes: Int,
    myVote: FeedVoteType? = nil,
    image: FeedImage?,
    replyCount: Int,
    replies: [FeedComment]
  ) {
    self.id = id
    self.postID = postID
    self.parentCommentID = parentCommentID
    self.content = content
    self.isDeleted = isDeleted
    self.isAnonymous = isAnonymous
    self.isKaistIP = isKaistIP
    self.authorName = authorName
    self.isAuthor = isAuthor
    self.isMyComment = isMyComment
    self.profileImageURL = profileImageURL
    self.createdAt = createdAt
    self.upvotes = upvotes
    self.downvotes = downvotes
    self.myVote = myVote
    self.image = image
    self.replyCount = replyCount
    self.replies = replies
  }
}
