import Foundation

public enum FeedViewPhase: String, Codable, Sendable {
  case loading
  case loaded
  case error
}
