import Testing
import Foundation
import Combine
import Synchronization
import BuddyDomain
import BuddyDataCore
@testable import BuddyDataiOS

@Suite("Session preservation")
@MainActor
struct AuthUseCaseTests {
  @Test(arguments: [NetworkError.noConnection, .timeout, .serverError(statusCode: 503),
    .unknown(underlying: URLError(.cancelled))])
  func transientRefreshFailurePreservesSession(error: NetworkError) async throws {
    let fixture = Fixture()
    fixture.service.result = .failure(error)

    await #expect(throws: AuthUseCaseError.self) { try await fixture.auth.refreshAccessToken(force: true) }

    #expect(fixture.storage.getRefreshToken() == "refresh-old")
    #expect(fixture.storage.clearCount == 0)
    #expect(isAuthenticated(fixture.auth))
  }

  @Test func unavailableKeychainDoesNotEraseTokensAndCanRecover() async throws {
    let fixture = Fixture()
    fixture.storage.readError = KeychainError(status: -25308) // errSecInteractionNotAllowed

    await #expect(throws: KeychainError.self) { try await fixture.auth.refreshAccessToken(force: true) }
    #expect(fixture.storage.clearCount == 0)
    #expect(isAuthenticated(fixture.auth))
    #expect(fixture.service.refreshCount == 0)

    fixture.storage.readError = nil
    #expect(try await fixture.auth.getValidAccessToken() == "access-new")
    #expect(fixture.storage.getRefreshToken() == "refresh-new")
  }

  @Test func confirmedMissingRefreshTokenRequiresSignIn() async throws {
    let fixture = Fixture()
    fixture.storage.refreshToken = nil

    await #expect(throws: AuthUseCaseError.self) { try await fixture.auth.refreshAccessToken(force: true) }
    #expect(fixture.storage.getAccessToken() == nil)
    #expect(fixture.storage.clearCount == 1)
    #expect(!isAuthenticated(fixture.auth))
  }

  @Test func rejectedRefreshTokenRequiresSignIn() async throws {
    let fixture = Fixture()
    fixture.service.result = .failure(NetworkError.unauthorized)

    await #expect(throws: AuthUseCaseError.self) { try await fixture.auth.refreshAccessToken(force: true) }
    #expect(fixture.storage.getRefreshToken() == nil)
    #expect(fixture.storage.getAccessToken() == nil)
    #expect(fixture.storage.clearCount == 1)
    #expect(!isAuthenticated(fixture.auth))
  }

  @Test func failedTokenWritePreservesSession() async throws {
    let fixture = Fixture()
    fixture.storage.saveError = KeychainError(status: -25308)

    await #expect(throws: AuthUseCaseError.self) { try await fixture.auth.refreshAccessToken(force: true) }
    #expect(fixture.storage.getRefreshToken() == "refresh-old")
    #expect(fixture.storage.clearCount == 0)
    #expect(isAuthenticated(fixture.auth))
  }

  @Test func concurrentRequestsShareOneRefresh() async throws {
    let fixture = Fixture()
    fixture.service.delay = .milliseconds(100)

    try await withThrowingTaskGroup(of: String.self) { group in
      for _ in 0..<20 {
        group.addTask { try await fixture.auth.getValidAccessToken() }
      }
      for try await token in group { #expect(token == "access-new") }
    }
    #expect(fixture.service.refreshCount == 1)
  }

  @Test func validTokensRemainUsableDuringRefreshCooldown() async throws {
    let fixture = Fixture()
    fixture.service.result = .failure(NetworkError.noConnection)
    await #expect(throws: AuthUseCaseError.self) { try await fixture.auth.refreshAccessToken(force: true) }
    try fixture.storage.save(accessToken: "access-from-widget", refreshToken: "refresh-from-widget")

    try await fixture.auth.refreshAccessToken(force: false)
    #expect(try await fixture.auth.getValidAccessToken() == "access-from-widget")
    #expect(fixture.service.refreshCount == 1)
  }

  private func isAuthenticated(_ auth: AuthUseCase) -> Bool {
    var value = false
    let subscription = auth.isAuthenticatedPublisher.sink { value = $0 }
    subscription.cancel()
    return value
  }
}

@MainActor
private final class Fixture {
  let storage = TestTokenStorage()
  let service = TestAuthenticationService()
  lazy var auth = makeAuth()

  init() { _ = auth }

  func makeAuth() -> AuthUseCase {
    AuthUseCase(authenticationService: service, tokenStorage: storage,
      araUserRepository: nil, feedUserRepository: nil, otlUserRepository: nil)
  }
}

@MainActor
private final class TestAuthenticationService: AuthenticationServiceProtocol {
  var result: Result<TokenResponse, Error> = .success(.init(accessToken: "access-new", refreshToken: "refresh-new"))
  var delay: Duration = .zero
  private(set) var refreshCount = 0

  func authenticate() async throws -> SignInResponse { throw AuthenticationServiceError.userCancelled }

  func refreshAccessToken(refreshToken: String) async throws -> TokenResponse {
    refreshCount += 1
    try await Task.sleep(for: delay)
    return try result.get()
  }

}

private final class TestTokenStorage: TokenStorageProtocol, Sendable {
  private struct State {
    var accessToken: String? = "access-old"
    var refreshToken: String? = "refresh-old"
    var expired = true
    var readError: (any Error)?
    var saveError: (any Error)?
    var clearCount = 0
  }
  private let state = Mutex(State())
  var tokenStatePublisher: AnyPublisher<TokenState?, Never> { Just(nil).eraseToAnyPublisher() }
  var currentTokenState: TokenState? { nil }
  var clearCount: Int { state.withLock { $0.clearCount } }
  var refreshToken: String? {
    get { state.withLock { $0.refreshToken } }
    set { state.withLock { $0.refreshToken = newValue } }
  }
  var readError: (any Error)? {
    get { state.withLock { $0.readError } }
    set { state.withLock { $0.readError = newValue } }
  }
  var saveError: (any Error)? {
    get { state.withLock { $0.saveError } }
    set { state.withLock { $0.saveError = newValue } }
  }
  func getAccessToken() -> String? { state.withLock { $0.accessToken } }
  func getRefreshToken() -> String? { try? readRefreshToken() }
  func readRefreshToken() throws -> String? {
    try state.withLock {
      if let error = $0.readError { throw error }
      return $0.refreshToken
    }
  }
  func isTokenExpired() -> Bool { state.withLock { $0.expired } }
  func getTokenExpirationDate() -> Date? { nil }
  func save(accessToken: String, refreshToken: String?) throws {
    try state.withLock {
      if let error = $0.saveError { throw error }
      $0.accessToken = accessToken
      $0.refreshToken = refreshToken
      $0.expired = false
    }
  }
  func clearTokens() {
    state.withLock {
      $0.accessToken = nil
      $0.refreshToken = nil
      $0.expired = true
      $0.clearCount += 1
    }
  }
}
