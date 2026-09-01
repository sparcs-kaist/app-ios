import Foundation

public struct FeedPostViewData: Codable, Sendable {
  public let id: String
  public let content: String
  public let authorName: String
  public let profileImageURL: String?
  public let createdAt: String
  public let timeText: String
  public let isAnonymous: Bool
  public let isKaistIP: Bool
  public let commentCount: Int
  public let upvotes: Int
  public let downvotes: Int
  public let score: Int
  public let myVote: String?
  public let isAuthor: Bool
  public let images: [FeedImageViewData]
}
