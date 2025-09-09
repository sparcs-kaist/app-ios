//
//  FeedComment.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation

struct FeedComment: Identifiable, Hashable, Sendable {
  let id: String
  let postID: String
  let parentCommentID: String?
  let content: String
  var isDeleted: Bool
  let isAnonymous: Bool
  let authorName: String
  let isAuthor: Bool
  let isMyComment: Bool
  let profileImageURL: URL?
  let createdAt: Date
  var upvotes: Int
  var downvotes: Int
  var myVote: FeedVoteType?
  let image: FeedImage?
  var replyCount: Int
  var replies: [FeedComment]
}
