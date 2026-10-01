import Testing
import Foundation
import Combine
import Synchronization
import BuddyDomain
@testable import BuddyDataCore

struct AuthTokenRefreshCoordinatorTests {
  @Test func concurrentCallersRefreshAndSaveOnce() async throws {
    let coordinator = AuthTokenRefreshCoordinator()
    let storage = RefreshTestStorage()
    let calls = Mutex(0)

    try await withThrowingTaskGroup(of: TokenResponse.self) { group in
      for _ in 0..<20 {
        group.addTask {
          try await coordinator.refresh(refreshToken: "old", tokenStorage: storage) {
            calls.withLock { $0 += 1 }
            try await Task.sleep(for: .milliseconds(50))
            return TokenResponse(accessToken: "new-access", refreshToken: "new")
          }
        }
      }
      for try await response in group { #expect(response.refreshToken == "new") }
    }
    #expect(calls.withLock { $0 } == 1)
    #expect(storage.getAccessToken() == "new-access")
    #expect(storage.getRefreshToken() == "new")
    #expect(storage.saveCount == 1)
  }

  @Test func alreadyRotatedTokenIsReusedWithoutNetworkRequest() async throws {
    let coordinator = AuthTokenRefreshCoordinator()
    let storage = RefreshTestStorage()
    try storage.save(accessToken: "rotated-access", refreshToken: "rotated")

    let result = try await coordinator.refresh(refreshToken: "old", tokenStorage: storage) {
      Issue.record("An already rotated token must not be refreshed again")
      throw NetworkError.unauthorized
    }
    #expect(result.accessToken == "rotated-access")
    #expect(result.refreshToken == "rotated")
    #expect(storage.saveCount == 1)
  }

  @Test func failedRefreshReleasesCoordinationForRetry() async throws {
    let coordinator = AuthTokenRefreshCoordinator()
    let storage = RefreshTestStorage()
    await #expect(throws: NetworkError.self) {
      try await coordinator.refresh(refreshToken: "old", tokenStorage: storage) {
        throw NetworkError.noConnection
      }
    }
    #expect(storage.getRefreshToken() == "old")
    #expect(storage.saveCount == 0)

    _ = try await coordinator.refresh(refreshToken: "old", tokenStorage: storage) {
      TokenResponse(accessToken: "new-access", refreshToken: "new")
    }
    #expect(storage.getRefreshToken() == "new")
  }
}

private final class RefreshTestStorage: TokenStorageProtocol, Sendable {
  private struct State {
    var accessToken: String? = "old-access"
    var refreshToken: String? = "old"
    var saveCount = 0
  }
  private let state = Mutex(State())
  var tokenStatePublisher: AnyPublisher<TokenState?, Never> { Just(nil).eraseToAnyPublisher() }
  var currentTokenState: TokenState? { nil }
  var saveCount: Int { state.withLock { $0.saveCount } }
  func getAccessToken() -> String? { state.withLock { $0.accessToken } }
  func getRefreshToken() -> String? { state.withLock { $0.refreshToken } }
  func readRefreshToken() throws -> String? { getRefreshToken() }
  func isTokenExpired() -> Bool { false }
  func getTokenExpirationDate() -> Date? { nil }
  func save(accessToken: String, refreshToken: String?) throws {
    state.withLock {
      $0.accessToken = accessToken
      $0.refreshToken = refreshToken
      $0.saveCount += 1
    }
  }
  func clearTokens() {
    state.withLock {
      $0.accessToken = nil
      $0.refreshToken = nil
    }
  }
}
