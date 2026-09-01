//
//  FeedPost.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

public struct FeedPost: Identifiable, Hashable, Sendable {
  public let id: String
  public let content: String
  public let isAnonymous: Bool
  public let isKaistIP: Bool
  public let authorName: String
  public let nickname: String?
  public let profileImageURL: URL?
  public let createdAt: Date
  public var commentCount: Int
  public var upvotes: Int
  public var downvotes: Int
  public var myVote: FeedVoteType?
  public let isAuthor: Bool
  public let images: [FeedImage]

  public init(
    id: String,
    content: String,
    isAnonymous: Bool,
    isKaistIP: Bool,
    authorName: String,
    nickname: String?,
    profileImageURL: URL?,
    createdAt: Date,
    commentCount: Int,
    upvotes: Int,
    downvotes: Int,
    myVote: FeedVoteType? = nil,
    isAuthor: Bool,
    images: [FeedImage]
  ) {
    self.id = id
    self.content = content
    self.isAnonymous = isAnonymous
    self.isKaistIP = isKaistIP
    self.authorName = authorName
    self.nickname = nickname
    self.profileImageURL = profileImageURL
    self.createdAt = createdAt
    self.commentCount = commentCount
    self.upvotes = upvotes
    self.downvotes = downvotes
    self.myVote = myVote
    self.isAuthor = isAuthor
    self.images = images
  }
}

