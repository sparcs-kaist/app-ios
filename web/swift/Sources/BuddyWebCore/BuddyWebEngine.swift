import Foundation
import BuddyFeedCore
import JavaScriptKit

private struct PageRequestBridge: Codable {
  let intent: String
  let url: String
}

private struct PageActionBridge: Codable {
  let state: FeedViewModelViewData
  let request: PageRequestBridge?
}

private struct VoteActionBridge: Codable {
  let state: FeedViewModelViewData
  let method: String
  let vote: String?
  let path: String
}

@JS final class BuddyWebEngine {
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
      throw bridgeError("Buddy could not read the feed response.")
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
      throw bridgeError("Unknown vote type.")
    }
    guard let command = viewModel.beginVote(postID: postID, type: voteType) else {
      throw bridgeError("This post is busy or no longer in the feed.")
    }

    do {
      return try encode(
        VoteActionBridge(
          state: viewModel.viewData(languageCode: languageCode),
          method: command.method,
          vote: command.vote?.rawValue,
          path: FeedAPIPath.vote(postID)
        )
      )
    } catch {
      throw bridgeError("Buddy could not update this vote.")
    }
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
    let bridgeRequest: PageRequestBridge?
    if let request {
      guard let url = FeedAPIPath.postsURL(
        baseURL: baseURL,
        cursor: request.cursor,
        limit: request.limit
      ) else {
        throw bridgeError("The feed URL is invalid.")
      }
      bridgeRequest = PageRequestBridge(intent: request.intent.rawValue, url: url)
    } else {
      bridgeRequest = nil
    }

    do {
      return try encode(
        PageActionBridge(
          state: viewModel.viewData(languageCode: languageCode),
          request: bridgeRequest
        )
      )
    } catch {
      throw bridgeError("Buddy could not prepare the feed request.")
    }
  }

  private func encodeState(languageCode: String) throws(JSException) -> String {
    do {
      return try viewModel.encodedViewData(languageCode: languageCode)
    } catch {
      throw bridgeError("Buddy could not prepare the feed.")
    }
  }

  private func pageIntent(_ rawValue: String) throws(JSException) -> FeedPageIntent {
    guard let intent = FeedPageIntent(rawValue: rawValue) else {
      throw bridgeError("Unknown feed request.")
    }
    return intent
  }

  private func encode<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return String(decoding: try encoder.encode(value), as: UTF8.self)
  }

  private func bridgeError(_ message: String) -> JSException {
    JSException(message: message)
  }
}
