//
//  AraPost.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPost: Identifiable, Hashable, Sendable {
  /// Whether the author is hidden. Ara sends the anonymous username translated ("익명" in
  /// Korean), so a username check misses it; the name type is authoritative.
  public var isAnonymous: Bool {
    nameType.map { $0 == .anonymous } ?? (author.username == "anonymous")
  }

  public enum AttachmentType: String, Sendable {
    case none = "NONE"
    case image = "IMAGE"
    case file = "NON_IMAGE"
    case both = "BOTH"
  }

  /// Whether the signed-in user has opened the post, from Ara's read log.
  public enum ReadStatus: Sendable {
    case unread
    case read
    /// Opened, but commented on or edited since.
    case updated
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
  /// How the author is named: their nickname, anonymous, or their real name.
  public let nameType: AraPostNicknameType?
  /// The price and sale state of a Market post; `nil` elsewhere.
  public let marketListing: AraMarketListing?
  /// Sent with list responses only; `nil` elsewhere.
  public var readStatus: ReadStatus?
  public let attachmentType: AttachmentType
  public let communicationArticleStatus: CommunicationArticleStatus?
  public let createdAt: Date
  public let isNSFW: Bool
  public let isPolitical: Bool
  public let views: Int

  /// The first image attached to the post, for a thumbnail.
  public var thumbnailURL: URL? {
    attachments?.first { $0.mimeType.hasPrefix("image/") }?.file
  }
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
    nameType: AraPostNicknameType? = nil,
    marketListing: AraMarketListing? = nil,
    readStatus: ReadStatus? = nil,
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
    self.nameType = nameType
    self.marketListing = marketListing
    self.readStatus = readStatus
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
