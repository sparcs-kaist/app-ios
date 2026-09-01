import Foundation

public enum FeedPageIntent: String, Codable, Sendable {
  case initial
  case refresh
  case next
}
