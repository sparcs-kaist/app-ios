import Foundation

public struct FeedViewModelViewData: Codable, Sendable {
  public let phase: FeedViewPhase
  public let posts: [FeedPostViewData]
  public let nextCursor: String?
  public let hasNext: Bool
  public let isRefreshing: Bool
  public let isLoadingMore: Bool
  public let votingPostIDs: [String]
  public let errorMessage: String?
  public let notice: String?
}
