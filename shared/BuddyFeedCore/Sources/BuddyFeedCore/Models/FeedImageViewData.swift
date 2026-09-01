import Foundation

public struct FeedImageViewData: Codable, Sendable {
  public let id: String
  public let url: String
  public let mimeType: String
  public let spoiler: Bool
}
