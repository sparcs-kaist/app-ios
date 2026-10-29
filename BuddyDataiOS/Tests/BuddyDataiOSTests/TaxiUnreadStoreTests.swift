import Testing
import Foundation
import Combine
import BuddyDomain
@testable import BuddyDataiOS

@Suite("Taxi unread counts")
@MainActor
struct TaxiUnreadStoreTests {
  @Test func openingTheAppFetchesTheCountsOnce() async throws {
    let fixture = Fixture()
    let store = fixture.store()

    try await until { store.totalCount == 2 }
    try await Task.sleep(for: .milliseconds(50))
    #expect(fixture.rooms.fetches == 1)
  }

  @Test func nothingIsFetchedOrListenedToInTheBackground() async throws {
    let fixture = Fixture(isInForeground: false)
    let store = fixture.store()

    try await Task.sleep(for: .milliseconds(100))
    #expect(fixture.rooms.fetches == 0)
    #expect(fixture.chats.connections == 0)
    #expect(store.totalCount == 0)
  }

  @Test func countsFetchedForASessionThatEndedAreDropped() async throws {
    let fixture = Fixture()
    fixture.rooms.isHeld = true
    let store = fixture.store()
    try await until { fixture.rooms.fetches == 1 }

    fixture.isAuthenticated.send(false)
    fixture.rooms.release()

    try await Task.sleep(for: .milliseconds(50))
    #expect(store.counts.isEmpty)
    #expect(fixture.notifications.removedAll > 0)
  }

  @Test func aChatThatArrivesDuringARefreshIsntLost() async throws {
    let fixture = Fixture()
    fixture.rooms.counts = ["ride": 0]
    let store = fixture.store()
    try await until { fixture.chats.connections == 1 && store.counts["ride"] == 0 }
    fixture.rooms.isHeld = true
    fixture.foreground.yield(false)
    fixture.foreground.yield(true)
    try await until { fixture.rooms.fetches == 2 }

    fixture.chats.send(in: "ride")
    try await until { store.counts["ride"] == 1 }
    fixture.rooms.release()

    try await Task.sleep(for: .milliseconds(50))
    #expect(store.counts["ride"] == 1)
  }

  @Test func aChatTheServerAlreadyCountedIsntCountedTwice() async throws {
    let fixture = Fixture()
    fixture.rooms.counts = ["ride": 0]
    let store = fixture.store()
    try await until { fixture.chats.connections == 1 && store.counts["ride"] == 0 }
    fixture.rooms.isHeld = true
    fixture.foreground.yield(false)
    fixture.foreground.yield(true)
    try await until { fixture.rooms.fetches == 2 }

    fixture.chats.send(in: "ride")
    try await until { store.counts["ride"] == 1 }
    fixture.rooms.counts = ["ride": 1]
    fixture.rooms.release()

    try await Task.sleep(for: .milliseconds(50))
    #expect(store.counts["ride"] == 1)
  }

  @Test func chatsStopCountingOnceYouSignOut() async throws {
    let fixture = Fixture()
    let store = fixture.store()
    try await until { fixture.chats.connections == 1 && store.totalCount == 2 }

    fixture.isAuthenticated.send(false)
    fixture.chats.send(in: "ride")

    try await Task.sleep(for: .milliseconds(50))
    #expect(store.totalCount == 0)
  }

  // MARK: - Helpers

  private func until(_ condition: () -> Bool) async throws {
    for _ in 0..<200 where !condition() {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(condition())
  }

  @MainActor
  final class Fixture {
    let isAuthenticated = CurrentValueSubject<Bool, Never>(true)
    let (foregroundStream, foreground) = AsyncStream<Bool>.makeStream()
    let rooms = Rooms()
    let chats = Chats()
    let notifications = Notifications()

    init(isInForeground: Bool = true) {
      foreground.yield(isInForeground)
    }

    func store() -> TaxiUnreadStore {
      let auth = Auth(isAuthenticated: isAuthenticated)
      let chats = chats
      let foregroundStream = foregroundStream
      return TaxiUnreadStore(
        taxiRoomRepository: rooms,
        makeTaxiChatService: { chats },
        userUseCase: nil,
        authUseCase: auth,
        notifications: notifications,
        isInForeground: { foregroundStream }
      )
    }
  }

  final class Rooms: TaxiRoomRepositoryProtocol, @unchecked Sendable {
    var counts = ["ride": 2]
    var fetches = 0
    /// While set, fetching waits for `release()`.
    var isHeld = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func release() {
      isHeld = false
      waiting.forEach { $0.resume() }
      waiting = []
    }

    func fetchMyRooms() async throws -> (onGoing: [TaxiRoom], done: [TaxiRoom]) {
      fetches += 1
      if isHeld {
        await withCheckedContinuation { waiting.append($0) }
      }
      return (counts.map { Self.room(id: $0.key, unreadCount: $0.value) }, [])
    }

    static func room(id: String, unreadCount: Int) -> TaxiRoom {
      let place = TaxiLocation(id: "place", title: LocalizedString(["en": "Place"]), priority: nil, latitude: 0, longitude: 0)
      return TaxiRoom(
        id: id, title: id, source: place, destination: place, departAt: .now, participants: [],
        madeAt: .now, capacity: 4, settlementTotal: nil, isDeparted: false, isOver: nil,
        unreadCount: unreadCount
      )
    }

    func fetchRooms() async throws -> [TaxiRoom] { [] }
    func fetchLocations() async throws -> [TaxiLocation] { [] }
    func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom { throw CancellationError() }
    func joinRoom(id: String) async throws -> TaxiRoom { throw CancellationError() }
    func leaveRoom(id: String) async throws -> TaxiRoom { throw CancellationError() }
    func getRoom(id: String) async throws -> TaxiRoom { throw CancellationError() }
    func getPublicRoom(id: String) async throws -> TaxiRoom { throw CancellationError() }
    func commitSettlement(id: String, settlementAmount: Int) async throws -> TaxiRoom { throw CancellationError() }
    func commitPayment(id: String) async throws -> TaxiRoom { throw CancellationError() }
    func updateArrival(id: String, isArrived: Bool) async throws -> TaxiRoom { throw CancellationError() }
    func updateCarrier(id: String, hasCarrier: Bool) async throws -> TaxiRoom { throw CancellationError() }
  }

  final class Chats: TaxiChatServiceProtocol, @unchecked Sendable {
    var connections = 0
    private var continuations: [AsyncStream<TaxiChat>.Continuation] = []

    func send(in roomID: String) {
      let chat = TaxiChat(
        roomID: roomID, type: .text, authorID: "someone else", authorName: nil,
        authorProfileURL: nil, authorIsWithdrew: false, content: "hi", time: .now,
        isValid: true, inOutNames: nil
      )
      continuations.forEach { $0.yield(chat) }
    }

    func liveChatStream() async -> AsyncStream<TaxiChat> {
      connections += 1
      let (stream, continuation) = AsyncStream<TaxiChat>.makeStream()
      continuations.append(continuation)
      return stream
    }

    func chatStream() async -> AsyncStream<[TaxiChat]> { AsyncStream { _ in } }
    func connectionStream() async -> AsyncStream<Bool> { AsyncStream { _ in } }
    func roomUpdateStream() async -> AsyncStream<String> { AsyncStream { _ in } }
    func connectWithCurrentAccessToken() async {}
    func reconnect() {}
    func disconnect() {}
  }

  final class Notifications: TaxiNotificationCleaning, @unchecked Sendable {
    var removedAll = 0
    func removeDelivered(roomID: String) {}
    func removeAllDelivered() { removedAll += 1 }
    func setBadgeCount(_ count: Int) {}
  }

  final class Auth: AuthUseCaseProtocol, @unchecked Sendable {
    let subject: CurrentValueSubject<Bool, Never>
    init(isAuthenticated: CurrentValueSubject<Bool, Never>) { subject = isAuthenticated }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
    var isAuthenticated: Bool { subject.value }
    func signIn() async throws {}
    func signOut() async throws {}
    func getAccessToken() -> String? { "token" }
    func getValidAccessToken() async throws -> String { "token" }
    func refreshAccessToken(force: Bool) async throws {}
  }
}
