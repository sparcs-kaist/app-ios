//
//  AraPost.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPost: Identifiable, Hashable, Sendable {
  public enum AttachmentType: String, Sendable {
    case none = "NONE"
    case image = "IMAGE"
    case file = "NON_IMAGE"
    case both = "BOTH"
  }

  public enum CommunicationArticleStatus: Int, Sendable {
    case answered = 2
    case waitingForAnswer = 1
    case pending = 0
  }

  public let id: Int
  public let isHidden: Bool
  public let hiddenReason: [String]
  public let overrideHidden: Bool?
  public let topic: AraBoardTopic?
  public let board: AraBoard?
  public let title: String?
  public let author: AraPostAuthor
  public let attachmentType: AttachmentType
  public let communicationArticleStatus: CommunicationArticleStatus?
  public let createdAt: Date
  public let isNSFW: Bool
  public let isPolitical: Bool
  public let views: Int
  public var commentCount: Int
  public var upvotes: Int
  public var downvotes: Int

  // for detailed
  public let attachments: [AraPostAttachment]?
  public let myCommentProfile: AraPostAuthor?
  public let isMine: Bool?
  public var comments: [AraPostComment]
  public let content: String?
  public var myVote: Bool?
  public var myScrap: Bool
  public let scrapId: Int?

  public init(
    id: Int,
    isHidden: Bool,
    hiddenReason: [String],
    overrideHidden: Bool?,
    topic: AraBoardTopic?,
    board: AraBoard?,
    title: String?,
    author: AraPostAuthor,
    attachmentType: AttachmentType,
    communicationArticleStatus: CommunicationArticleStatus?,
    createdAt: Date,
    isNSFW: Bool,
    isPolitical: Bool,
    views: Int,
    commentCount: Int,
    upvotes: Int,
    downvotes: Int,
    attachments: [AraPostAttachment]?,
    myCommentProfile: AraPostAuthor?,
    isMine: Bool?,
    comments: [AraPostComment],
    content: String?,
    myVote: Bool? = nil,
    myScrap: Bool,
    scrapId: Int?
  ) {
    self.id = id
    self.isHidden = isHidden
    self.hiddenReason = hiddenReason
    self.overrideHidden = overrideHidden
    self.topic = topic
    self.board = board
    self.title = title
    self.author = author
    self.attachmentType = attachmentType
    self.communicationArticleStatus = communicationArticleStatus
    self.createdAt = createdAt
    self.isNSFW = isNSFW
    self.isPolitical = isPolitical
    self.views = views
    self.commentCount = commentCount
    self.upvotes = upvotes
    self.downvotes = downvotes
    self.attachments = attachments
    self.myCommentProfile = myCommentProfile
    self.isMine = isMine
    self.comments = comments
    self.content = content
    self.myVote = myVote
    self.myScrap = myScrap
    self.scrapId = scrapId
  }
}
