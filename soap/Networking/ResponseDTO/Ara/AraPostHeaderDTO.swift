//
//  AraPostHeaderDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostHeaderDTO: Codable {
  let id: Int
  let isHidden: Bool
  let hiddenReason: [String]
  let overrideHidden: Bool?
  let topic: AraBoardTopicDTO?
  let title: String?
  let author: AraPostAuthorDTO
  let readStatus: String
  let attachmentType: String
  let communicationArticleStatus: Int?
  let createdAt: String
  let isNSFW: Bool
  let isPolitical: Bool
  let views: Int
  let commentCount: Int
  let positiveVoteCount: Int
  let negativeVoteCount: Int

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
    case positiveVoteCount = "positive_vote_count"
    case negativeVoteCount = "negative_vote_count"
  }
}


extension AraPostHeaderDTO {
  func toModel() -> AraPostHeader {
    AraPostHeader(
      id: id,
      isHidden: isHidden,
      hiddenReason: hiddenReason,
      overrideHidden: overrideHidden,
      topic: topic?.toModel(),
      title: title,
      author: author.toModel(),
      attachmentType: AraPostHeader.AttachmentType(rawValue: attachmentType) ?? .none,
      communicationArticleStatus: communicationArticleStatus != nil ? AraPostHeader
        .CommunicationArticleStatus(rawValue: communicationArticleStatus!) : nil,
      createdAt: createdAt.toDate() ?? Date(),
      isNSFW: isNSFW,
      isPolitical: isPolitical,
      views: views,
      commentCount: commentCount,
      positiveVoteCount: positiveVoteCount,
      negativeVoteCount: negativeVoteCount
    )
  }
}
