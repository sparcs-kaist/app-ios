//
//  FeedTestFixtures.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation
import BuddyDomain

public enum FeedTestFixtures {
  public static func makePost(
    id: String = "post-1",
    content: String = "Test content",
    upvotes: Int = 5,
    downvotes: Int = 2,
    myVote: FeedVoteType? = nil,
    commentCount: Int = 0,
    isAuthor: Bool = false
  ) -> FeedPost {
    FeedPost(
      id: id,
      content: content,
      isAnonymous: false,
      isKaistIP: true,
      authorName: "Test Author",
      nickname: "tester",
      profileImageURL: nil,
      createdAt: Date(),
      commentCount: commentCount,
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote,
      isAuthor: isAuthor,
      images: []
    )
  }

  public static func makeComment(
    id: String = "comment-1",
    postID: String = "post-1",
    parentCommentID: String? = nil,
    content: String = "Test comment",
    upvotes: Int = 3,
    downvotes: Int = 1,
    myVote: FeedVoteType? = nil,
    isDeleted: Bool = false,
    isAuthor: Bool = false,
    replies: [FeedComment] = []
  ) -> FeedComment {
    FeedComment(
      id: id,
      postID: postID,
      parentCommentID: parentCommentID,
      content: content,
      isDeleted: isDeleted,
      isAnonymous: false,
      isKaistIP: true,
      authorName: "Test Commenter",
      isAuthor: isAuthor,
      isMyComment: isAuthor,
      profileImageURL: nil,
      createdAt: Date(),
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote,
      image: nil,
      replyCount: replies.count,
      replies: replies
    )
  }

  public static func makePostPage(
    posts: [FeedPost] = [],
    nextCursor: String? = nil,
    hasNext: Bool = false
  ) -> FeedPostPage {
    FeedPostPage(items: posts, nextCursor: nextCursor, hasNext: hasNext)
  }
}
