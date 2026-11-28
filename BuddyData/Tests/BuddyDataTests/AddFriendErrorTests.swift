import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

/// How otlplus-server's add-friend refusals reach the user.
@Suite("Add friend errors")
struct AddFriendErrorTests {
  @Test func successAddsQuietly() async throws {
    try await repository(status: 201, body: #"{"friend":{"id":1,"name":"A","isFavorite":false}}"#)
      .addFriend(code: "ACD347")
  }

  @Test func unknownCodeIsInvalid() async {
    let repository = repository(status: 400, body: #"{"statusCode":400,"message":"Invalid friend code","error":"Bad Request"}"#)
    await #expect(throws: AddFriendError.invalidCode) { try await repository.addFriend(code: "ACD347") }
  }

  @Test func ownCodeIsTold() async {
    let repository = repository(status: 400, body: #"{"code":"SELF_FRIENDSHIP","message":"You cannot add yourself as a friend"}"#)
    await #expect(throws: AddFriendError.ownCode) { try await repository.addFriend(code: "ACD347") }
  }

  @Test func rateLimitCarriesTheWait() async {
    let repository = repository(status: 429, body: #"{"statusCode":429}"#, headers: ["Retry-After": "75"])
    await #expect(throws: AddFriendError.tooManyAttempts(retryAfter: 75)) { try await repository.addFriend(code: "ACD347") }
  }

  @Test func limiterDownIsUnavailable() async {
    let repository = repository(status: 503, body: "{}")
    await #expect(throws: AddFriendError.unavailable) { try await repository.addFriend(code: "ACD347") }
  }

  @Test func otherFailuresStayNetworkErrors() async {
    let repository = repository(status: 500, body: "{}")
    await #expect(throws: NetworkError.self) { try await repository.addFriend(code: "ACD347") }
  }

  @Test func waitIsRoundedUpToMinutes() {
    let message = AddFriendError.tooManyAttempts(retryAfter: 75).errorDescription ?? ""
    #expect(message.contains("2"))
    #expect(AddFriendError.tooManyAttempts(retryAfter: nil).errorDescription != message)
  }

  @Test func unauthorizedStillRefreshesFirst() async throws {
    let calls = Calls()
    let previous = AuthRetryConfig.tokenRefresher
    AuthRetryConfig.tokenRefresher = { calls.refreshed() }
    defer { AuthRetryConfig.tokenRefresher = previous }
    let repository = FriendRepository(provider: MoyaProvider<FriendTarget>(endpointClosure: { target in
      let status = calls.next() == 0 ? 401 : 201
      return Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(status, Data("{}".utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub))
    try await repository.addFriend(code: "ACD347")
    #expect(calls.refreshCount == 1)
  }

  private func repository(status: Int, body: String, headers: [String: String] = [:]) -> FriendRepository {
    FriendRepository(provider: MoyaProvider<FriendTarget>(endpointClosure: { target in
      let url = URL(string: target.baseURL.absoluteString + target.path)!
      return Endpoint(
        url: url.absoluteString,
        sampleResponseClosure: {
          .response(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers)!, Data(body.utf8))
        },
        method: target.method, task: target.task, httpHeaderFields: target.headers
      )
    }, stubClosure: MoyaProvider.immediatelyStub))
  }
}

private final class Calls: @unchecked Sendable {
  private let lock = NSLock()
  private var requests = 0
  private var refreshes = 0
  var refreshCount: Int { lock.withLock { refreshes } }
  func next() -> Int { lock.withLock { defer { requests += 1 }; return requests } }
  func refreshed() { lock.withLock { refreshes += 1 } }
}
