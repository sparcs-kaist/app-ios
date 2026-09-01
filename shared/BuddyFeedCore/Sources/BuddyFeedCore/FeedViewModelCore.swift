import Foundation

/// Cross-platform feed presentation state. Platform layers provide HTTP and
/// analytics; this type owns the view state transitions shared by iOS and web.
public struct FeedViewModelCore: Sendable {
  private var timeline: FeedTimeline
  private var voteSnapshots: [String: FeedPost] = [:]
  private var activePageRequest: FeedPageRequest?

  public private(set) var phase: FeedViewPhase
  public private(set) var errorMessage: String?
  public private(set) var notice: String?
  public private(set) var isRefreshing = false
  public private(set) var isLoadingMore = false
  public private(set) var votingPostIDs: Set<String> = []

  public var posts: [FeedPost] {
    get { timeline.posts }
    set { timeline.setPosts(newValue) }
  }

  public var hasNext: Bool { timeline.hasNext }
  public var nextCursor: String? { timeline.nextCursor }

  public init(posts: [FeedPost] = [], phase: FeedViewPhase = .loading) {
    self.timeline = FeedTimeline(posts: posts)
    self.phase = phase
  }

  public mutating func beginInitialLoad(limit: Int = 20) -> FeedPageRequest? {
    guard activePageRequest == nil else { return nil }
    phase = .loading
    errorMessage = nil
    notice = nil
    let request = FeedPageRequest(intent: .initial, cursor: nil, limit: limit)
    activePageRequest = request
    return request
  }

  public mutating func beginRefresh(limit: Int = 20) -> FeedPageRequest? {
    guard activePageRequest == nil else { return nil }
    isRefreshing = true
    errorMessage = nil
    notice = nil
    let request = FeedPageRequest(intent: .refresh, cursor: nil, limit: limit)
    activePageRequest = request
    return request
  }

  public mutating func beginNextPage(limit: Int = 20) -> FeedPageRequest? {
    guard activePageRequest == nil, phase == .loaded, timeline.hasNext else { return nil }
    isLoadingMore = true
    let request = FeedPageRequest(intent: .next, cursor: timeline.nextCursor, limit: limit)
    activePageRequest = request
    return request
  }

  public mutating func receive(_ page: FeedPostPage, for intent: FeedPageIntent) {
    guard activePageRequest?.intent == intent else { return }
    if intent == .next {
      timeline.append(page)
    } else {
      timeline.replace(with: page)
    }
    finishPageRequest()
    phase = .loaded
    errorMessage = nil
  }

  public mutating func failPage(_ intent: FeedPageIntent, message: String) {
    guard activePageRequest?.intent == intent else { return }
    finishPageRequest()
    if intent == .initial || timeline.posts.isEmpty {
      phase = .error
      errorMessage = message
    } else {
      phase = .loaded
      notice = message
    }
  }

  public mutating func loadPreview(_ page: FeedPostPage = FeedPreview.page()) {
    timeline.replace(with: page)
    activePageRequest = nil
    voteSnapshots.removeAll()
    votingPostIDs.removeAll()
    phase = .loaded
    errorMessage = nil
    notice = nil
    isRefreshing = false
    isLoadingMore = false
  }

  public mutating func removePost(id: String) {
    timeline.removePost(id: id)
  }

  public mutating func beginVote(postID: String, type: FeedVoteType) -> FeedVoteCommand? {
    guard !votingPostIDs.contains(postID),
          let original = timeline.posts.first(where: { $0.id == postID }),
          let transition = timeline.toggleVote(postID: postID, type: type) else {
      return nil
    }

    voteSnapshots[postID] = original
    votingPostIDs.insert(postID)
    notice = nil

    switch transition.request {
    case .delete:
      return FeedVoteCommand(postID: postID, method: "DELETE", vote: nil)
    case .set(let vote):
      return FeedVoteCommand(postID: postID, method: "POST", vote: vote)
    }
  }

  public mutating func commitVote(postID: String) {
    voteSnapshots.removeValue(forKey: postID)
    votingPostIDs.remove(postID)
  }

  public mutating func failVote(postID: String, message: String) {
    if let snapshot = voteSnapshots.removeValue(forKey: postID) {
      timeline.restore(snapshot)
    }
    votingPostIDs.remove(postID)
    notice = message
  }

  public mutating func dismissNotice() {
    notice = nil
  }

  public func viewData(
    referenceDate: Date = Date(),
    languageCode: String = "en"
  ) -> FeedViewModelViewData {
    let timelineData = timeline.viewData(referenceDate: referenceDate, languageCode: languageCode)
    return FeedViewModelViewData(
      phase: phase,
      posts: timelineData.posts,
      nextCursor: timelineData.nextCursor,
      hasNext: timelineData.hasNext,
      isRefreshing: isRefreshing,
      isLoadingMore: isLoadingMore,
      votingPostIDs: votingPostIDs.sorted(),
      errorMessage: errorMessage,
      notice: notice
    )
  }

  public func encodedViewData(
    referenceDate: Date = Date(),
    languageCode: String = "en"
  ) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return String(decoding: try encoder.encode(viewData(referenceDate: referenceDate, languageCode: languageCode)), as: UTF8.self)
  }

  private mutating func finishPageRequest() {
    activePageRequest = nil
    isRefreshing = false
    isLoadingMore = false
  }
}
