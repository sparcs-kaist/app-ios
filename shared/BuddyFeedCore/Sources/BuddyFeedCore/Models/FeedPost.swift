import Foundation

public struct FeedPost: Identifiable, Codable, Hashable, Sendable {
  public let id: String
  public let content: String
  public let isAnonymous: Bool
  public let isKaistIP: Bool
  public let authorName: String
  public let nickname: String?
  public let profileImageURL: URL?
  public let createdAt: Date
  public var commentCount: Int
  public var upvotes: Int
  public var downvotes: Int
  public var myVote: FeedVoteType?
  public let isAuthor: Bool
  public let images: [FeedImage]

  public init(
    id: String,
    content: String,
    isAnonymous: Bool,
    isKaistIP: Bool,
    authorName: String,
    nickname: String?,
    profileImageURL: URL?,
    createdAt: Date,
    commentCount: Int,
    upvotes: Int,
    downvotes: Int,
    myVote: FeedVoteType? = nil,
    isAuthor: Bool,
    images: [FeedImage]
  ) {
    self.id = id
    self.content = content
    self.isAnonymous = isAnonymous
    self.isKaistIP = isKaistIP
    self.authorName = authorName
    self.nickname = nickname
    self.profileImageURL = profileImageURL
    self.createdAt = createdAt
    self.commentCount = commentCount
    self.upvotes = upvotes
    self.downvotes = downvotes
    self.myVote = myVote
    self.isAuthor = isAuthor
    self.images = images
  }
}

public extension FeedPost {
  var score: Int { upvotes - downvotes }

  /// The optimistic vote transition used by both iOS and the web client.
  func togglingVote(_ type: FeedVoteType) -> FeedVoteTransition {
    var updated = self

    if myVote == type {
      updated.myVote = nil
      if type == .up {
        updated.upvotes = max(0, updated.upvotes - 1)
      } else {
        updated.downvotes = max(0, updated.downvotes - 1)
      }
      return FeedVoteTransition(post: updated, request: .delete)
    }

    if myVote == .up {
      updated.upvotes = max(0, updated.upvotes - 1)
    } else if myVote == .down {
      updated.downvotes = max(0, updated.downvotes - 1)
    }

    updated.myVote = type
    if type == .up {
      updated.upvotes += 1
    } else {
      updated.downvotes += 1
    }
    return FeedVoteTransition(post: updated, request: .set(type))
  }
}
