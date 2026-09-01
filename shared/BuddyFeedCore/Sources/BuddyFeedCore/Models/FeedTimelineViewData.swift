import Foundation

public struct FeedTimelineViewData: Codable, Sendable {
  public let posts: [FeedPostViewData]
  public let nextCursor: String?
  public let hasNext: Bool
}
