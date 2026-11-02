import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Taxi favourite routes")
struct TaxiFavoriteRoutesTests {
  @Test func fetchReadsPopulatedPlacesAndDropsRemovedOnes() async throws {
    let body = """
    [
      {"_id": "r1", "user": "u1", "createdAt": "2026-11-01T09:00:00.000Z",
       "from": {"_id": "l1", "koName": "카이스트", "enName": "KAIST"},
       "to": {"_id": "l2", "koName": "대전역", "enName": "Daejeon Station"}},
      {"_id": "r2", "user": "u1", "createdAt": "2026-11-02T09:00:00.000Z",
       "from": null,
       "to": {"_id": "l2", "koName": "대전역", "enName": "Daejeon Station"}}
    ]
    """
    let stub = TaxiUserAPIStub { _ in (200, body) }

    let routes = try await stub.repository.fetchFavoriteRoutes()

    #expect(stub.targets.map(\.path) == ["/users/getFavorite"])
    #expect(routes.map(\.id) == ["r1"])
    #expect(routes.first?.sourceID == "l1")
    #expect(routes.first?.destinationID == "l2")
    #expect(routes.first?.createdAt == "2026-11-01T09:00:00.000Z".toDate())
  }

  @Test func createSendsBothPlacesAndReadsUnpopulatedReply() async throws {
    let body = """
    {"_id": "r3", "user": "u1", "from": "l1", "to": "l2", "createdAt": "2026-11-02T10:00:00.000Z"}
    """
    let stub = TaxiUserAPIStub { _ in (200, body) }

    let route = try await stub.repository.createFavoriteRoute(sourceID: "l1", destinationID: "l2")

    #expect(route == TaxiFavoriteRoute(
      id: "r3",
      sourceID: "l1",
      destinationID: "l2",
      createdAt: try #require("2026-11-02T10:00:00.000Z".toDate())
    ))
    let target = try #require(stub.targets.first)
    #expect(target.path == "/users/createFavorite")
    #expect(target.method == .post)
    guard case let .requestParameters(parameters, _) = target.task else {
      Issue.record("Expected a JSON body")
      return
    }
    #expect(parameters as? [String: String] == ["from": "l1", "to": "l2"])
  }

  @Test func deletePostsToTheRoutesPath() async throws {
    let stub = TaxiUserAPIStub { _ in (200, #"{"_id": "r1", "from": "l1", "to": "l2"}"#) }

    try await stub.repository.deleteFavoriteRoute(id: "r1")

    #expect(stub.targets.map(\.path) == ["/users/deleteFavorite/r1"])
    #expect(stub.targets.map(\.method) == [.post])
  }

  @Test func createThrowsWhenTheRouteIsAlreadySaved() async {
    let stub = TaxiUserAPIStub { _ in (400, #"{"error": "Users/createFavorite: route already exists"}"#) }

    await #expect(throws: NetworkError.self) {
      _ = try await stub.repository.createFavoriteRoute(sourceID: "l1", destinationID: "l2")
    }
  }
}

private final class TaxiUserAPIStub: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [TaxiUserTarget] = []
  let response: @Sendable (TaxiUserTarget) -> (Int, String)
  var targets: [TaxiUserTarget] { lock.withLock { recorded } }

  init(response: @escaping @Sendable (TaxiUserTarget) -> (Int, String)) { self.response = response }

  var repository: TaxiUserRepository {
    let provider = MoyaProvider<TaxiUserTarget>(endpointClosure: { target in
      self.lock.withLock { self.recorded.append(target) }
      let (status, body) = self.response(target)
      return Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(status, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub)
    return TaxiUserRepository(provider: provider)
  }
}
