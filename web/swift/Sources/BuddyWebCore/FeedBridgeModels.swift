import BuddyFeedCore

struct FeedPageRequestBridge: Codable {
  let intent: String
  let url: String
}

struct FeedPageActionBridge: Codable {
  let state: FeedViewModelViewData
  let request: FeedPageRequestBridge?
}

struct FeedVoteActionBridge: Codable {
  let state: FeedViewModelViewData
  let method: String
  let vote: String?
  let path: String
}
