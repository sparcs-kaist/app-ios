//
//  AraPost.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPost: Identifiable, Hashable, Sendable {
  enum AttachmentType: String {
    case none = "NONE"
    case image = "IMAGE"
    case file = "NON_IMAGE"
    case both = "BOTH"
  }

  enum CommunicationArticleStatus: Int {
    case answered = 2
    case waitingForAnswer = 1
    case pending = 0
  }

  let id: Int
  let isHidden: Bool
  let hiddenReason: [String]
  let overrideHidden: Bool?
  let topic: AraBoardTopic?
  let board: AraBoard?
  let title: String?
  let author: AraPostAuthor
  let attachmentType: AttachmentType
  let communicationArticleStatus: CommunicationArticleStatus?
  let createdAt: Date
  let isNSFW: Bool
  let isPolitical: Bool
  let views: Int
  var commentCount: Int
  var upvotes: Int
  var downvotes: Int

  // for detailed
  let attachments: [AraPostAttachment]?
  let myCommentProfile: AraPostAuthor?
  let isMine: Bool?
  var comments: [AraPostComment]?
  let content: String?
  var myVote: Bool?
  var myScrap: Bool?
}
