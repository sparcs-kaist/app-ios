import Foundation

public struct FeedImagePayload: Codable, Sendable {
  public let id: String
  public let url: String
  public let mimeType: String
  public let size: Int
  public let spoiler: Bool?

  enum CodingKeys: String, CodingKey {
    case id, url, spoiler
    case mimeType = "mime_type"
    case size = "size_bytes"
  }

  public func toModel() -> FeedImage? {
    guard let url = URL(string: url) else { return nil }
    return FeedImage(id: id, url: url, mimeType: mimeType, size: size, spoiler: spoiler)
  }
}
