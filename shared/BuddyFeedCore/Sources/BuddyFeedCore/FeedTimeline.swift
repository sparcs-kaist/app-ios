import Foundation

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
