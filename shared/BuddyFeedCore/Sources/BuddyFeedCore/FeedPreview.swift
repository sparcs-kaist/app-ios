import Foundation

public enum FeedPreview {
  public static func page(referenceDate: Date = Date()) -> FeedPostPage {
    FeedPostPage(
      items: [
        FeedPost(
          id: "preview-campus-evening",
          content: "The evening light by the duck pond is unreal today. A good reminder to step away from the lab for ten minutes 🌇",
          isAnonymous: false,
          isKaistIP: true,
          authorName: "Curious Otter",
          nickname: "Curious Otter",
          profileImageURL: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/imgs/NupjukOTL.png"),
          createdAt: referenceDate.addingTimeInterval(-12 * 60),
          commentCount: 8,
          upvotes: 31,
          downvotes: 1,
          myVote: nil,
          isAuthor: false,
          images: [
            FeedImage(
              id: "preview-image-campus",
              url: URL(string: "https://dlnutnvhcnj0u.cloudfront.net/orphaned/07adc127-fb22-42f4-9483-52fdf8e72229.jpg")!,
              mimeType: "image/jpeg",
              size: 1_258_382,
              spoiler: false
            )
          ]
        ),
        FeedPost(
          id: "preview-lunch",
          content: "What is everyone’s underrated lunch spot near campus? Looking for somewhere quiet enough to read between classes.",
          isAnonymous: true,
          isKaistIP: false,
          authorName: "Anonymous",
          nickname: nil,
          profileImageURL: nil,
          createdAt: referenceDate.addingTimeInterval(-48 * 60),
          commentCount: 19,
          upvotes: 22,
          downvotes: 0,
          myVote: .up,
          isAuthor: false,
          images: []
        ),
        FeedPost(
          id: "preview-study",
          content: "오늘 새벽까지 같이 공부할 사람 있나요? 중앙도서관 2층에 있을 예정입니다. 부담 없이 와서 각자 할 일 해요!",
          isAnonymous: false,
          isKaistIP: true,
          authorName: "Sleepy Squirrel",
          nickname: "Sleepy Squirrel",
          profileImageURL: nil,
          createdAt: referenceDate.addingTimeInterval(-2.5 * 3_600),
          commentCount: 5,
          upvotes: 16,
          downvotes: 2,
          myVote: nil,
          isAuthor: false,
          images: []
        ),
        FeedPost(
          id: "preview-club",
          content: "Small win of the week: our team finally got the prototype to work. Thanks to the people who answered my very late-night questions here.",
          isAnonymous: false,
          isKaistIP: false,
          authorName: "Bright Badger",
          nickname: "Bright Badger",
          profileImageURL: nil,
          createdAt: referenceDate.addingTimeInterval(-22 * 3_600),
          commentCount: 3,
          upvotes: 44,
          downvotes: 1,
          myVote: nil,
          isAuthor: false,
          images: []
        )
      ],
      nextCursor: nil,
      hasNext: false
    )
  }
}
