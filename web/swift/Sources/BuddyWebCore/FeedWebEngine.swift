import BuddyFeedCore
import JavaScriptKit

/// Browser bridge for the Feed feature. The shared view model owns Feed
/// behavior; this class only translates that behavior across BridgeJS.
@JS final class FeedWebEngine {
  private var viewModel = FeedViewModelCore()

  @JS init() {}

  @JS func loadPreview(languageCode: String) throws(JSException) -> String {
    viewModel.loadPreview()
    return try encodeState(languageCode: languageCode)
  }

  @JS func beginInitialLoad(baseURL: String, languageCode: String) throws(JSException) -> String {
    try encodePageAction(
      request: viewModel.beginInitialLoad(),
      baseURL: baseURL,
      languageCode: languageCode
    )
  }

  @JS func beginRefresh(baseURL: String, languageCode: String) throws(JSException) -> String {
    try encodePageAction(
      request: viewModel.beginRefresh(),
      baseURL: baseURL,
      languageCode: languageCode
    )
  }

  @JS func beginNextPage(baseURL: String, languageCode: String) throws(JSException) -> String {
    try encodePageAction(
      request: viewModel.beginNextPage(),
      baseURL: baseURL,
      languageCode: languageCode
    )
  }

  @JS func receivePage(json: String, intent: String, languageCode: String) throws(JSException) -> String {
    do {
      let page = try FeedPageDecoder.decode(json)
      viewModel.receive(page, for: try pageIntent(intent))
      return try encodeState(languageCode: languageCode)
    } catch let error as JSException {
      throw error
    } catch {
      throw BridgeJSON.error("Buddy could not read the feed response.")
    }
  }

  @JS func failPage(intent: String, message: String, languageCode: String) throws(JSException) -> String {
    viewModel.failPage(try pageIntent(intent), message: message)
    return try encodeState(languageCode: languageCode)
  }

  @JS func currentState(languageCode: String) throws(JSException) -> String {
    try encodeState(languageCode: languageCode)
  }

  @JS func toggleVote(postID: String, vote: String, languageCode: String) throws(JSException) -> String {
    guard let voteType = FeedVoteType(rawValue: vote) else {
      throw BridgeJSON.error("Unknown vote type.")
    }
    guard let command = viewModel.beginVote(postID: postID, type: voteType) else {
      throw BridgeJSON.error("This post is busy or no longer in the feed.")
    }

    return try BridgeJSON.encode(
      FeedVoteActionBridge(
        state: viewModel.viewData(languageCode: languageCode),
        method: command.method,
        vote: command.vote?.rawValue,
        path: FeedAPIPath.vote(postID)
      ),
      failureMessage: "Buddy could not update this vote."
    )
  }

  @JS func commitVote(postID: String, languageCode: String) throws(JSException) -> String {
    viewModel.commitVote(postID: postID)
    return try encodeState(languageCode: languageCode)
  }

  @JS func failVote(postID: String, message: String, languageCode: String) throws(JSException) -> String {
    viewModel.failVote(postID: postID, message: message)
    return try encodeState(languageCode: languageCode)
  }

  @JS func dismissNotice(languageCode: String) throws(JSException) -> String {
    viewModel.dismissNotice()
    return try encodeState(languageCode: languageCode)
  }

  private func encodePageAction(
    request: FeedPageRequest?,
    baseURL: String,
    languageCode: String
  ) throws(JSException) -> String {
    let bridgeRequest: FeedPageRequestBridge?
    if let request {
      guard let url = FeedAPIPath.postsURL(
        baseURL: baseURL,
        cursor: request.cursor,
        limit: request.limit
      ) else {
        throw BridgeJSON.error("The feed URL is invalid.")
      }
      bridgeRequest = FeedPageRequestBridge(intent: request.intent.rawValue, url: url)
    } else {
      bridgeRequest = nil
    }

    return try BridgeJSON.encode(
      FeedPageActionBridge(
        state: viewModel.viewData(languageCode: languageCode),
        request: bridgeRequest
      ),
      failureMessage: "Buddy could not prepare the feed request."
    )
  }

  private func encodeState(languageCode: String) throws(JSException) -> String {
    try BridgeJSON.encode(
      viewModel.viewData(languageCode: languageCode),
      failureMessage: "Buddy could not prepare the feed."
    )
  }

  private func pageIntent(_ rawValue: String) throws(JSException) -> FeedPageIntent {
    guard let intent = FeedPageIntent(rawValue: rawValue) else {
      throw BridgeJSON.error("Unknown feed request.")
    }
    return intent
  }
}
