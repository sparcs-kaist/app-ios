import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Notification preferences")
struct NotificationPreferencesTests {
  @Test func fetchesThisDevicesPreferencesAndSkipsUnknownCategories() async throws {
    let stub = FCMAPIStub { _ in
      (200, #"""
      {"preferences":[
        {"category":"feed_comment","is_enabled":true},
        {"category":"taxi_event","is_enabled":false},
        {"category":"something_new","is_enabled":false}
      ]}
      """#)
    }

    let preferences = try await stub.repository.fetchNotificationPreferences(deviceUUID: "device-1")

    #expect(preferences == [.feedComment: true, .taxiEvent: false])
    let request = try #require(stub.targets.first)
    #expect(request.path == "/notification/preferences")
    #expect(request.method == .get)
    guard case .requestParameters(let parameters, let encoding) = request.task else {
      Issue.record("Expected the device in the query")
      return
    }
    #expect(encoding is URLEncoding)
    #expect(parameters as? [String: String] == ["device_uuid": "device-1"])
  }

  @Test func turnsACategoryOffForThisDevice() async throws {
    let stub = FCMAPIStub { _ in (200, #"{"category":"taxi_chat","is_enabled":false}"#) }

    try await stub.repository.setNotificationPreference(.taxiChat, isEnabled: false, deviceUUID: "device-1")

    let request = try #require(stub.targets.first)
    #expect(request.path == "/notification/preferences/taxi_chat")
    #expect(request.method == .put)
    guard case .requestParameters(let payload, let encoding) = request.task else {
      Issue.record("Expected a JSON payload")
      return
    }
    #expect(encoding is JSONEncoding)
    #expect(payload["device_uuid"] as? String == "device-1")
    #expect(payload["is_enabled"] as? Bool == false)
  }

  @Test func failedChangeThrows() async {
    let stub = FCMAPIStub { _ in (500, "") }

    await #expect(throws: (any Error).self) {
      try await stub.repository.setNotificationPreference(.ara, isEnabled: false, deviceUUID: "device-1")
    }
  }
}

private final class FCMAPIStub: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [FCMTarget] = []
  let response: @Sendable (FCMTarget) -> (Int, String)
  var targets: [FCMTarget] { lock.withLock { recorded } }

  init(response: @escaping @Sendable (FCMTarget) -> (Int, String)) { self.response = response }

  var repository: FCMRepository {
    let provider = MoyaProvider<FCMTarget>(endpointClosure: { target in
      self.lock.withLock { self.recorded.append(target) }
      let (status, body) = self.response(target)
      return Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(status, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub)
    return FCMRepository(provider: provider)
  }
}
