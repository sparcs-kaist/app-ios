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

public struct FeedImageViewData: Codable, Sendable {
  public let id: String
  public let url: String
  public let mimeType: String
  public let spoiler: Bool
}

public struct FeedTimelineViewData: Codable, Sendable {
  public let posts: [FeedPostViewData]
  public let nextCursor: String?
  public let hasNext: Bool
}

public struct FeedTimeline: Sendable {
  public private(set) var posts: [FeedPost]
  public private(set) var nextCursor: String?
  public private(set) var hasNext: Bool

  public init(posts: [FeedPost] = [], nextCursor: String? = nil, hasNext: Bool = false) {
    self.posts = posts
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }

  public mutating func replace(with page: FeedPostPage) {
    posts = page.items
    nextCursor = page.nextCursor
    hasNext = page.hasNext
  }

  public mutating func append(_ page: FeedPostPage) {
    let existingIDs = Set(posts.map(\.id))
    posts.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
    nextCursor = page.nextCursor
    hasNext = page.hasNext
  }

  @discardableResult
  public mutating func toggleVote(postID: String, type: FeedVoteType) -> FeedVoteTransition? {
    guard let index = posts.firstIndex(where: { $0.id == postID }) else { return nil }
    let transition = posts[index].togglingVote(type)
    posts[index] = transition.post
    return transition
  }

  public mutating func restore(_ post: FeedPost) {
    guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
    posts[index] = post
  }

  public mutating func setPosts(_ posts: [FeedPost]) {
    self.posts = posts
  }

  public mutating func removePost(id: String) {
    posts.removeAll { $0.id == id }
  }

  public func viewData(referenceDate: Date = Date(), languageCode: String = "en") -> FeedTimelineViewData {
    FeedTimelineViewData(
      posts: posts.map { post in
        FeedPostViewData(
          id: post.id,
          content: post.content,
          authorName: post.authorName,
          profileImageURL: post.profileImageURL?.absoluteString,
          createdAt: FeedISO8601.string(from: post.createdAt),
          timeText: FeedRelativeTime.string(from: post.createdAt, relativeTo: referenceDate, languageCode: languageCode),
          isAnonymous: post.isAnonymous,
          isKaistIP: post.isKaistIP,
          commentCount: post.commentCount,
          upvotes: post.upvotes,
          downvotes: post.downvotes,
          score: post.score,
          myVote: post.myVote?.rawValue,
          isAuthor: post.isAuthor,
          images: post.images.map {
            FeedImageViewData(
              id: $0.id,
              url: $0.url.absoluteString,
              mimeType: $0.mimeType,
              spoiler: $0.spoiler ?? false
            )
          }
        )
      },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }

  public func encodedViewData(referenceDate: Date = Date(), languageCode: String = "en") throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(viewData(referenceDate: referenceDate, languageCode: languageCode))
    return String(decoding: data, as: UTF8.self)
  }
}

public enum FeedRelativeTime {
  public static func string(from date: Date, relativeTo now: Date = Date(), languageCode: String = "en") -> String {
    let seconds = max(0, Int(now.timeIntervalSince(date)))
    let korean = languageCode.lowercased().hasPrefix("ko")

    if seconds < 60 { return korean ? "방금 전" : "just now" }
    if seconds < 3_600 {
      let minutes = seconds / 60
      return korean ? "\(minutes)분 전" : "\(minutes) min ago"
    }
    if seconds < 86_400 {
      let hours = seconds / 3_600
      return korean ? "\(hours)시간 전" : "\(hours) hr\(hours == 1 ? "" : "s") ago"
    }
    if seconds < 604_800 {
      let days = seconds / 86_400
      return korean ? "\(days)일 전" : "\(days) day\(days == 1 ? "" : "s") ago"
    }
    return FeedISO8601.shortDate(from: date)
  }
}

public enum FeedISO8601 {
  public static func string(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
  }

  public static func shortDate(from date: Date) -> String {
    let components = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
  }
}

public enum FeedAPIPath {
  public static let posts = "/posts"

  public static func post(_ postID: String) -> String { "/posts/\(postID)" }
  public static func vote(_ postID: String) -> String { "\(post(postID))/vote" }
  public static func report(_ postID: String) -> String { "\(post(postID))/report" }

  public static func postsURL(baseURL: String, cursor: String?, limit: Int) -> String? {
    guard var components = URLComponents(string: baseURL + posts) else { return nil }
    var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
    if let cursor, !cursor.isEmpty {
      queryItems.append(URLQueryItem(name: "cursor", value: cursor))
    }
    components.queryItems = queryItems
    return components.url?.absoluteString
  }
}
