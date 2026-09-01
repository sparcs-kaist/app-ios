import Foundation

public struct FeedVoteTransition: Sendable {
  public let post: FeedPost
  public let request: FeedVoteRequest

  public init(post: FeedPost, request: FeedVoteRequest) {
    self.post = post
    self.request = request
  }
}
