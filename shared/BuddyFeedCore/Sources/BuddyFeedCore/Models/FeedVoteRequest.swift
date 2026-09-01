import Foundation

public enum FeedVoteRequest: Equatable, Sendable {
  case set(FeedVoteType)
  case delete
}
