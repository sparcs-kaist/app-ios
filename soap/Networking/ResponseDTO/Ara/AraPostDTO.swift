//
//  AraPostDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostDTO: Codable {
  let id: Int
  let isHidden: Bool
  let hiddenReason: [String]
  let overrideHidden: Bool?
  let topic: AraBoardTopicDTO?
  let title: String?
  let author: AraPostAuthorDTO
  let readStatus: String?
  let attachmentType: String?
  let communicationArticleStatus: Int?
  let createdAt: String
  let isNSFW: Bool
  let isPolitical: Bool
  let views: Int
  let commentCount: Int
  let upvotes: Int
  let downvotes: Int

  // for detailed
  let attachments: [AraPostAttachmentDTO]?
  let myCommentProfile: AraPostAuthorDTO?
  let isMine: Bool?
  let comments: [AraPostCommentDTO]?
  let content: String?
  let myVote: Bool?
  let myScrap: Bool?

  enum CodingKeys: String, CodingKey {
    case id
    case isHidden = "is_hidden"
    case hiddenReason = "why_hidden"
    case overrideHidden = "can_override_hidden"
    case topic = "parent_topic"
    case title
    case author = "created_by"
    case readStatus = "read_status"
    case attachmentType = "attachment_type"
    case communicationArticleStatus = "communication_article_status"
    case createdAt = "created_at"
    case isNSFW = "is_content_sexual"
    case isPolitical = "is_content_social"
    case views = "hit_count"
    case commentCount = "comment_count"
    case upvotes = "positive_vote_count"
    case downvotes = "negative_vote_count"

    case attachments
    case myCommentProfile = "my_comment_profile"
    case isMine = "is_mine"
    case comments
    case content
    case myVote = "my_vote"
    case myScrap = "my_scrap"
  }
}


extension AraPostDTO {
  func toModel() -> AraPost {
    AraPost(
      id: id,
      isHidden: isHidden,
      hiddenReason: hiddenReason,
      overrideHidden: overrideHidden,
      topic: topic?.toModel(),
      title: title,
      author: author.toModel(),
      attachmentType: AraPost.AttachmentType(rawValue: attachmentType ?? "") ?? .none,
      communicationArticleStatus: communicationArticleStatus != nil ? AraPost
        .CommunicationArticleStatus(rawValue: communicationArticleStatus!) : nil,
      createdAt: createdAt.toDate() ?? Date(),
      isNSFW: isNSFW,
      isPolitical: isPolitical,
      views: views,
      commentCount: commentCount,
      upvotes: upvotes,
      downvotes: downvotes,
      attachments: attachments?.compactMap { $0.toModel() },
      myCommentProfile: myCommentProfile?.toModel(),
      isMine: isMine,
      comments: comments?.compactMap { $0.toModel() },
      content: content,
      myVote: myVote,
      myScrap: myScrap
    )
  }
}
