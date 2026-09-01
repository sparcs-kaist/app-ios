//
//  FeedComment+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation

extension FeedComment: Mockable { }

public extension FeedComment {
  static var mock: FeedComment {
    FeedComment(
      id: UUID().uuidString,
      postID: UUID().uuidString,
      parentCommentID: nil,
      content: "샘플 댓글입니다. 이 댓글은 테스트 목적으로 사용됩니다.",
      isDeleted: false,
      isAnonymous: false,
      isKaistIP: false,
      authorName: "멋진호랑이677",
      isAuthor: false,
      isMyComment: true,
      profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
      createdAt: Date(),
      upvotes: 5,
      downvotes: 1,
      myVote: .up,
      image: nil,
      replyCount: 2,
      replies: []
    )
  }

  static var mockList: [FeedComment] {
    [
      // 일반 댓글 (답글이 있는 경우)
      FeedComment(
        id: "2084eb46-cae5-4a87-8b08-4246680c1dbc",
        postID: "4680556d-5db8-46ed-bc52-8fb859885bd6",
        parentCommentID: nil,
        content: "string",
        isDeleted: false,
        isAnonymous: false,
        isKaistIP: false,
        authorName: "멋진호랑이677",
        isAuthor: false,
        isMyComment: true,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        image: nil,
        replyCount: 1,
        replies: [
          FeedComment(
            id: "812a6383-636c-4d85-9704-b2a49b0a43fd",
            postID: "4680556d-5db8-46ed-bc52-8fb859885bd6",
            parentCommentID: "2084eb46-cae5-4a87-8b08-4246680c1dbc",
            content: "(deleted)",
            isDeleted: true,
            isAnonymous: false,
            isKaistIP: false,
            authorName: "멋진호랑이677",
            isAuthor: false,
            isMyComment: true,
            profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            upvotes: 0,
            downvotes: 0,
            myVote: nil,
            image: nil,
            replyCount: 0,
            replies: []
          )
        ]
      ),
      
      // 익명 댓글
      FeedComment(
        id: "395749fe-6e1f-48cb-a144-a906992e34a6",
        postID: "4680556d-5db8-46ed-bc52-8fb859885bd6",
        parentCommentID: nil,
        content: "test comments",
        isDeleted: false,
        isAnonymous: true,
        isKaistIP: false,
        authorName: "Anonymous 1",
        isAuthor: false,
        isMyComment: true,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        image: nil,
        replyCount: 0,
        replies: []
      ),
      
      // 이미지가 있는 댓글
      FeedComment(
        id: "bb0a2224-b57a-42b6-8d81-f9b4af382ea1",
        postID: "4680556d-5db8-46ed-bc52-8fb859885bd6",
        parentCommentID: nil,
        content: "test comments with an image",
        isDeleted: false,
        isAnonymous: true,
        isKaistIP: false,
        authorName: "Anonymous 1",
        isAuthor: false,
        isMyComment: true,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        image: FeedImage(
          id: "1dc53a00-baf4-4dcb-8b7a-454e5fc9aad0",
          url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/9015ab49-8261-477a-960c-715beac38af1.jpg")!,
          mimeType: "image/png",
          size: 1258382,
          spoiler: false
        ),
        replyCount: 0,
        replies: []
      ),
      
      // 투표가 있는 댓글
      FeedComment(
        id: UUID().uuidString,
        postID: UUID().uuidString,
        parentCommentID: nil,
        content: "이 댓글은 많은 투표를 받았습니다!",
        isDeleted: false,
        isAnonymous: false,
        isKaistIP: true,
        authorName: "인기사용자",
        isAuthor: false,
        isMyComment: false,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
        upvotes: 25,
        downvotes: 3,
        myVote: .up,
        image: nil,
        replyCount: 0,
        replies: []
      ),
      
      // 삭제된 댓글
      FeedComment(
        id: UUID().uuidString,
        postID: UUID().uuidString,
        parentCommentID: nil,
        content: "(deleted)",
        isDeleted: true,
        isAnonymous: false,
        isKaistIP: true,
        authorName: "삭제된사용자",
        isAuthor: false,
        isMyComment: false,
        profileImageURL: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        image: nil,
        replyCount: 0,
        replies: []
      ),
      
      // 긴 내용의 댓글
      FeedComment(
        id: UUID().uuidString,
        postID: UUID().uuidString,
        parentCommentID: nil,
        content: "이것은 매우 긴 댓글입니다. 여러 줄에 걸쳐 내용을 작성할 수 있고, 다양한 정보를 포함할 수 있습니다. 이 mock 데이터는 테스트 목적으로 사용되며, UI에서 긴 텍스트가 어떻게 표시되는지 확인할 수 있습니다.",
        isDeleted: false,
        isAnonymous: false,
        isKaistIP: false,
        authorName: "긴댓글작성자",
        isAuthor: false,
        isMyComment: false,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/LongCommentUser.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
        upvotes: 8,
        downvotes: 2,
        myVote: .down,
        image: nil,
        replyCount: 0,
        replies: []
      ),
      
      // 답글이 많은 댓글
      FeedComment(
        id: UUID().uuidString,
        postID: UUID().uuidString,
        parentCommentID: nil,
        content: "이 댓글에는 많은 답글이 있습니다.",
        isDeleted: false,
        isAnonymous: false,
        isKaistIP: false,
        authorName: "답글많은사용자",
        isAuthor: false,
        isMyComment: false,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/ReplyUser.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
        upvotes: 12,
        downvotes: 1,
        myVote: nil,
        image: nil,
        replyCount: 5,
        replies: [
          FeedComment(
            id: UUID().uuidString,
            postID: UUID().uuidString,
            parentCommentID: UUID().uuidString,
            content: "첫 번째 답글입니다.",
            isDeleted: false,
            isAnonymous: false,
            isKaistIP: true,
            authorName: "답글작성자1",
            isAuthor: false,
            isMyComment: false,
            profileImageURL: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
            upvotes: 3,
            downvotes: 0,
            myVote: nil,
            image: nil,
            replyCount: 0,
            replies: []
          ),
          FeedComment(
            id: UUID().uuidString,
            postID: UUID().uuidString,
            parentCommentID: UUID().uuidString,
            content: "두 번째 답글입니다.",
            isDeleted: false,
            isAnonymous: true,
            isKaistIP: false,
            authorName: "Anonymous 2",
            isAuthor: false,
            isMyComment: false,
            profileImageURL: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            upvotes: 1,
            downvotes: 1,
            myVote: nil,
            image: nil,
            replyCount: 0,
            replies: []
          )
        ]
      ),
      
      // 익명 댓글 (글 작성자의 댓글)
      FeedComment(
        id: "395749fe-6e1f-48cb-a144-a906992e34a6",
        postID: "4680556d-5db8-46ed-bc52-8fb859885bd6",
        parentCommentID: nil,
        content: "test comments",
        isDeleted: false,
        isAnonymous: true,
        isKaistIP: true,
        authorName: "Anonymous 1",
        isAuthor: true,
        isMyComment: true,
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/CatOTL.png"),
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        image: nil,
        replyCount: 0,
        replies: []
      ),
    ]
  }
}
