//
//  FeedPost.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

struct FeedPost: Identifiable, Hashable {
  let id: String
  let content: String
  let isAnonymous: Bool
  let authorName: String
  let nickname: String?
  let profileImageURL: URL?
  let createdAt: Date
  let commentCount: Int
  let upvotes: Int
  let downvotes: Int
  let myVote: FeedVoteType?
  let isAuthor: Bool
  let images: [FeedImage]
}

