import Foundation

public struct FeedVoteCommand: Sendable {
  public let postID: String
  public let method: String
  public let vote: FeedVoteType?

  public init(postID: String, method: String, vote: FeedVoteType?) {
    self.postID = postID
    self.method = method
    self.vote = vote
  }
}
