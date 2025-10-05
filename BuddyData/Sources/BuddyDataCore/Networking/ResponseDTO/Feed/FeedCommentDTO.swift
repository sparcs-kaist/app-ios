//
//  FeedCommentDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation
import BuddyDomain

struct FeedCommentDTO: Codable {
  let id: String
  let postID: String
  let parentCommentID: String?
  let content: String
  let isDeleted: Bool
  let isAnonymous: Bool
  let authorName: String
  let isAuthor: Bool
  let isMyComment: Bool
  let profileImageURL: String?
  let createdAt: String
  let upvotes: Int
  let downvotes: Int
  let myVote: String?
  let image: FeedImageDTO?
  let replyCount: Int
  let replies: [FeedCommentDTO]

  enum CodingKeys: String, CodingKey {
    case id
    case postID = "post_id"
    case parentCommentID = "parent_comment_id"
    case content
    case isDeleted = "is_deleted"
    case isAnonymous = "is_anonymous"
    case authorName = "author_name"
    case isAuthor = "is_author"
    case isMyComment = "is_my_comment"
    case profileImageURL = "profile_image_url"
    case createdAt = "created_at"
    case upvotes
    case downvotes
    case myVote = "my_vote"
    case image
    case replyCount = "reply_count"
    case replies
  }
}

extension FeedCommentDTO {
  func toModel() -> FeedComment {
    FeedComment(
      id: id,
      postID: postID,
      parentCommentID: parentCommentID,
      content: content,
      isDeleted: isDeleted,
      isAnonymous: isAnonymous,
      authorName: authorName,
      isAuthor: isAuthor,
      isMyComment: isMyComment,
      profileImageURL: profileImageURL.flatMap(URL.init(string:)),
      createdAt: createdAt.toDate() ?? Date(),
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote.flatMap(FeedVoteType.init(rawValue:)),
      image: image?.toModel(),
      replyCount: replyCount,
      replies: replies.compactMap { $0.toModel() }
    )
  }
}
