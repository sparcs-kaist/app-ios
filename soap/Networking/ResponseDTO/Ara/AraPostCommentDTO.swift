//
//  AraPostCommentDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostCommentDTO: Codable {
  let id: Int
  let isHidden: Bool
  let hiddenReason: [String]
  let overrideHidden: Bool?
  let myVote: Bool?
  let isMine: Bool
  let content: String
  let author: AraPostAuthorDTO
  let comments: [AraPostCommentDTO]?
  let createdAt: String
  let positiveVoteCount: Int
  let negativeVoteCount: Int
  let parentPost: Int
  let parentComment: Int?

  enum CodingKeys: String, CodingKey {
    case id
    case isHidden = "is_hidden"
    case hiddenReason = "why_hidden"
    case overrideHidden = "can_override_hidden"
    case myVote = "my_vote"
    case isMine = "is_mine"
    case content
    case author = "created_by"
    case comments
    case createdAt = "created_at"
    case positiveVoteCount = "positive_vote_count"
    case negativeVoteCount = "negative_vote_count"
    case parentPost = "parent_article"
    case parentComment = "parent_comment"
  }
}


extension AraPostCommentDTO {
  func toModel() -> AraPostComment {
    AraPostComment(
      id: id,
      isHidden: isHidden,
      hiddenReason: hiddenReason,
      overrideHidden: overrideHidden,
      myVote: myVote,
      isMine: isMine,
      content: content,
      author: author.toModel(),
      comments: comments?.compactMap { $0.toModel() },
      createdAt: createdAt.toDate() ?? Date(),
      positiveVoteCount: positiveVoteCount,
      negativeVoteCount: negativeVoteCount,
      parentPost: parentPost,
      parentComment: parentComment
    )
  }
}
