import Foundation

public struct FeedPostPagePayload: Codable, Sendable {
  public let items: [FeedPostPayload]
  public let nextCursor: String?
  public let hasNext: Bool

  enum CodingKeys: String, CodingKey {
    case items
    case nextCursor = "next_cursor"
    case hasNext = "has_next"
  }

  public func toModel(fallbackDate: Date = Date()) -> FeedPostPage {
    FeedPostPage(
      items: items.map { $0.toModel(fallbackDate: fallbackDate) },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }
}
