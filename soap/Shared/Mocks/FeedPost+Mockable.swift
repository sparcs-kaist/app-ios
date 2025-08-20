//
//  FeedPost+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

extension FeedPost: Mockable {
  static var mock: FeedPost {
    FeedPost(
      id: "0170487b-7027-41ab-a906-16784dbf817b",
      content: "sample post with image",
      isAnonymous: false,
      authorName: "멋진다람쥐632",
      nickname: "멋진다람쥐632",
      profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
      createdAt: Date(),
      commentCount: 0,
      upvotes: 0,
      downvotes: 0,
      myVote: nil,
      isAuthor: true,
      images: [
        FeedImage(
          id: "f9d64c0c-3511-4634-aa75-6a4fb55ce241",
          url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/07adc127-fb22-42f4-9483-52fdf8e72229.jpg")!,
          mimeType: "image/png",
          size: 1258382,
          spoiler: false
        )
      ]
    )
  }

  static var mockList: [FeedPost] {
    [
      FeedPost(
        id: "0170487b-7027-41ab-a906-16784dbf817b",
        content: "sample post with image",
        isAnonymous: false,
        authorName: "멋진다람쥐632",
        nickname: "멋진다람쥐632",
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
        commentCount: 0,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        isAuthor: true,
        images: [
          FeedImage(
            id: "f9d64c0c-3511-4634-aa75-6a4fb55ce241",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/07adc127-fb22-42f4-9483-52fdf8e72229.jpg")!,
            mimeType: "image/png",
            size: 1258382,
            spoiler: false
          )
        ]
      ),
      FeedPost(
        id: "fbfb084f-145b-4c6d-9df9-82364bf0bc53",
        content: "sample post",
        isAnonymous: false,
        authorName: "멋진다람쥐632",
        nickname: "멋진다람쥐632",
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        commentCount: 0,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        isAuthor: true,
        images: [
          FeedImage(
            id: "bfd87f95-9c32-45b1-a89f-9425a56df106",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/0c351f1b-3837-4329-9ced-de317fcfea6a.jpg")!,
            mimeType: "image/png",
            size: 219138,
            spoiler: false
          ),
          FeedImage(
            id: "f9d64c0c-3511-4634-aa75-6a4fba5ce241",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/07adc127-fb22-42f4-9483-52fdf8e72229.jpg")!,
            mimeType: "image/png",
            size: 1258382,
            spoiler: false
          )
        ]
      ),
      FeedPost(
        id: "fbfb084f-145b-4c6d-9df9-823a4bf0bc53",
        content: "sample post",
        isAnonymous: false,
        authorName: "멋진다람쥐632",
        nickname: "멋진다람쥐632",
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        commentCount: 0,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        isAuthor: true,
        images: [
          FeedImage(
            id: "c79bb063-4dd8-4ccb-9899-f0d9b7f9e33a",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/b899e2e7-d68d-4c94-8c8c-2eae607ec6d2.jpg")!,
            mimeType: "image/png",
            size: 48507,
            spoiler: false
          )
        ]
      ),
      FeedPost(
        id: "fbfb084f-145b-4c6d-9df9-823ajbf0bc53",
        content: "sample post",
        isAnonymous: false,
        authorName: "멋진다람쥐632",
        nickname: "멋진다람쥐632",
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
        commentCount: 0,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        isAuthor: true,
        images: [
          FeedImage(
            id: "8cfc810d-9750-48cf-bb2f-2e9f2a742523",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/c54cac50-ff4b-4866-a544-c73b65ca7eb7.jpg")!,
            mimeType: "image/png",
            size: 15823,
            spoiler: false
          )
        ]
      ),
      FeedPost(
        id: "7357bd13-60bf-4259-a762-3fb2dc5238e4",
        content: "anonymously shit posting",
        isAnonymous: true,
        authorName: "Anonymous",
        nickname: nil,
        profileImageURL: nil,
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
        commentCount: 0,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        isAuthor: true,
        images: [
          FeedImage(
            id: "bfd87f95-9c32-45b1-a89f-9425a56df106",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/0c351f1b-3837-4329-9ced-de317fcfea6a.jpg")!,
            mimeType: "image/png",
            size: 219138,
            spoiler: false
          )
        ]
      ),
      FeedPost(
        id: "c8279e90-fa7c-41b5-89ff-8bc7ee85e95d",
        content: "testing multiline post\nthis is the second line",
        isAnonymous: false,
        authorName: "멋진다람쥐632",
        nickname: "멋진다람쥐632",
        profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
        createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
        commentCount: 0,
        upvotes: 0,
        downvotes: 0,
        myVote: nil,
        isAuthor: true,
        images: [
          FeedImage(
            id: "bb498078-33f8-4985-a81a-f15e20bc3016",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/831db235-768a-4218-80a9-05833cf4aca0.jpg")!,
            mimeType: "image/jpeg",
            size: 97060,
            spoiler: false
          ),
          FeedImage(
            id: "0b293bee-d454-4a93-b875-203f840886f5",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/ac3c75e4-0b1e-4d15-ad6e-c14073bfdb18.jpg")!,
            mimeType: "image/jpeg",
            size: 135460,
            spoiler: false
          ),
          FeedImage(
            id: "47166f0f-43fc-420d-9449-c94ad79adc9b",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/7df0c9e9-e1e1-40c7-9d67-c23843dd962a.jpg")!,
            mimeType: "image/jpeg",
            size: 103165,
            spoiler: false
          )
        ]
      ),
      FeedPost(
        id: "mock-post-5",
        content: "이것은 한국어로 작성된 긴 포스트입니다. 여러 줄에 걸쳐 내용을 작성할 수 있고, 이미지도 첨부할 수 있습니다. 이 mock 데이터는 테스트 목적으로 사용됩니다.",
        isAnonymous: true,
        authorName: "테스트사용자",
        nickname: "테스트닉네임",
        profileImageURL: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        commentCount: 5,
        upvotes: 12,
        downvotes: 2,
        myVote: .up,
        isAuthor: false,
        images: []
      ),
      FeedPost(
        id: "mock-post-6",
        content: "Another anonymous post for testing",
        isAnonymous: true,
        authorName: "Anonymous",
        nickname: nil,
        profileImageURL: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        commentCount: 3,
        upvotes: 8,
        downvotes: 1,
        myVote: .down,
        isAuthor: false,
        images: [
          FeedImage(
            id: "f9d64c0c-3511-4634-aa75-6a4fb35ce241",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/07adc127-fb22-42f4-9483-52fdf8e72229.jpg")!,
            mimeType: "image/png",
            size: 1258382,
            spoiler: false
          ),
          FeedImage(
            id: "f9d64c0c-3511-4634-aa75-6a4fb55ce242",
            url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/07adc127-fb22-42f4-9483-52fdf8e72229.jpg")!,
            mimeType: "image/png",
            size: 1258382,
            spoiler: false
          )
        ]
      )
    ]
  }
}
