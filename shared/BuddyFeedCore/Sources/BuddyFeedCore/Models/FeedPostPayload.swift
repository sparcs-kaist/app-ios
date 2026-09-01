import Foundation

public struct FeedPostPayload: Codable, Sendable {
  public let id: String
  public let content: String
  public let isAnonymous: Bool
  public let isKaistIP: Bool
  public let authorName: String
  public let nickname: String?
  public let profileImageURL: String?
  public let createdAt: String
  public let commentCount: Int
  public let upvotes: Int
  public let downvotes: Int
  public let myVote: String?
  public let isAuthor: Bool
  public let images: [FeedImagePayload]

  enum CodingKeys: String, CodingKey {
    case id, content, nickname, upvotes, downvotes, images
    case isAnonymous = "is_anonymous"
    case isKaistIP = "is_kaist_ip"
    case authorName = "author_name"
    case profileImageURL = "profile_image_url"
    case createdAt = "created_at"
    case commentCount = "comment_count"
    case myVote = "my_vote"
    case isAuthor = "is_author"
  }

  public func toModel(fallbackDate: Date = Date()) -> FeedPost {
    FeedPost(
      id: id,
      content: content,
      isAnonymous: isAnonymous,
      isKaistIP: isKaistIP,
      authorName: authorName,
      nickname: nickname,
      profileImageURL: profileImageURL.flatMap(URL.init(string:)),
      createdAt: FeedDateParser.date(from: createdAt) ?? fallbackDate,
      commentCount: commentCount,
      upvotes: upvotes,
      downvotes: downvotes,
      myVote: myVote.flatMap(FeedVoteType.init(rawValue:)),
      isAuthor: isAuthor,
      images: images.compactMap { $0.toModel() }
    )
  }
}
