import Foundation

public struct FeedPageRequest: Codable, Equatable, Sendable {
  public let intent: FeedPageIntent
  public let cursor: String?
  public let limit: Int

  public init(intent: FeedPageIntent, cursor: String?, limit: Int) {
    self.intent = intent
    self.cursor = cursor
    self.limit = limit
  }
}
