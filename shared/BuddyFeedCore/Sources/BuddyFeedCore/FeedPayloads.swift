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

public enum FeedPageDecoder {
  public static func decode(_ data: Data) throws -> FeedPostPage {
    try JSONDecoder().decode(FeedPostPagePayload.self, from: data).toModel()
  }

  public static func decode(_ json: String) throws -> FeedPostPage {
    try decode(Data(json.utf8))
  }
}

public enum FeedDateParser {
  public static func date(from value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
  }
}
