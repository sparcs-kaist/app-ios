//
//  UseCaseTestFixtures.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation
import BuddyDomain

public enum UseCaseTestFixtures {
  public static func makePost(
    id: String = "post-1",
    content: String = "Test content",
    upvotes: Int = 5,
    downvotes: Int = 2,
    myVote: FeedVoteType? = nil
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
      commentCount: 0,
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote,
      isAuthor: false,
      images: []
    )
  }

  public static func makeComment(
    id: String = "comment-1",
    postID: String = "post-1",
    parentCommentID: String? = nil,
    content: String = "Test comment"
  ) -> FeedComment {
    FeedComment(
      id: id,
      postID: postID,
      parentCommentID: parentCommentID,
      content: content,
      isDeleted: false,
      isAnonymous: false,
      isKaistIP: true,
      authorName: "Test Commenter",
      isAuthor: false,
      isMyComment: false,
      profileImageURL: nil,
      createdAt: Date(),
      upvotes: 3,
      downvotes: 1,
      myVote: nil,
      image: nil,
      replyCount: 0,
      replies: []
    )
  }

  public static func makePostPage(
    posts: [FeedPost] = [],
    nextCursor: String? = nil,
    hasNext: Bool = false
  ) -> FeedPostPage {
    FeedPostPage(items: posts, nextCursor: nextCursor, hasNext: hasNext)
  }

  public static func makeCreatePost(
    content: String = "New post content",
    isAnonymous: Bool = false,
    images: [FeedImage] = []
  ) -> FeedCreatePost {
    FeedCreatePost(content: content, isAnonymous: isAnonymous, images: images)
  }

  public static func makeCreateComment(
    content: String = "New comment",
    isAnonymous: Bool = false,
    image: FeedImage? = nil
  ) -> FeedCreateComment {
    FeedCreateComment(content: content, isAnonymous: isAnonymous, image: image)
  }
}
