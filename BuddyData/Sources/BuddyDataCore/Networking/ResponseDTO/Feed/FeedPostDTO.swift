//
//  FeedPostDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import BuddyDomain

struct FeedPostDTO: Codable {
  let id: String
  let content: String
  let isAnonymous: Bool
  let authorName: String
  let nickname: String?
  let profileImageURL: String?
  let createdAt: String
  let commentCount: Int
  let upvotes: Int
  let downvotes: Int
  let myVote: String?
  let isAuthor: Bool
  let images: [FeedImageDTO]

  enum CodingKeys: String, CodingKey {
    case id
    case content
    case isAnonymous = "is_anonymous"
    case authorName = "author_name"
    case nickname
    case profileImageURL = "profile_image_url"
    case createdAt = "created_at"
    case commentCount = "comment_count"
    case upvotes
    case downvotes
    case myVote = "my_vote"
    case isAuthor = "is_author"
    case images
  }
}


extension FeedPostDTO {
  func toModel() -> FeedPost {
    FeedPost(
      id: id,
      content: content,
      isAnonymous: isAnonymous,
      authorName: authorName,
      nickname: nickname,
      profileImageURL: profileImageURL.flatMap(URL.init(string:)),
      createdAt: createdAt.toDate() ?? Date(),
      commentCount: commentCount,
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote.flatMap(FeedVoteType.init(rawValue:)),
      isAuthor: isAuthor,
      images: images.compactMap { $0.toModel() }
    )
  }
}
