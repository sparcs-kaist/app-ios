//
//  NearbyFriendUseCaseTests.swift
//  BuddyDataTests
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import CryptoKit
import Testing
import BuddyDomain
import BuddyTestSupport
@testable import BuddyDataCore

/// A clock the tests move by hand.
final class TestClock: @unchecked Sendable {
  private let lock = NSLock()
  private var date = Date(timeIntervalSince1970: 1_790_590_000)

  var now: Date { lock.withLock { date } }

  func advance(_ seconds: TimeInterval) {
    lock.withLock { date = date.addingTimeInterval(seconds) }
  }
}

/// One simulated phone: a use case with its own friend use case, sharing the
/// relay and clock with the other phones in the test.
struct Phone {
  let useCase: NearbyFriendUseCase
  let friends: MockFriendUseCase
  let session: NearbySession

  var id: NearbyPeer.ID { session.token.hexString }

  static func make(
    name: String,
    code: String,
    relay: MockNearbyRelayRepository,
    clock: TestClock,
    deviceID: String = UUID().uuidString,
    useCase existing: NearbyFriendUseCase? = nil
  ) async -> Phone {
    let friends = MockFriendUseCase()
    friends.fetchMyCodeResult = .success(code)
    let useCase = existing ?? NearbyFriendUseCase(
      beaconService: nil,
      relayRepository: relay,
      friendUseCase: friends,
      crashlyticsService: nil,
      deviceID: deviceID,
      now: { clock.now }
    )
    let session = await useCase.prepare(displayName: name)
    await useCase.publishPresence()
    return Phone(useCase: useCase, friends: friends, session: session)
  }

  /// Hears `other`'s beacon close by and resolves it.
  func sees(_ other: Phone, rssi: Int = -50, clock: TestClock) async {
    await useCase.ingest(BeaconSighting(token: other.session.token, rssi: rssi, seenAt: clock.now))
    await useCase.tick()
  }

  func receive() async throws {
    try await useCase.pollOnce(wait: 0)
  }

  func state(of other: Phone) async -> NearbyPeerState? {
    await useCase.visiblePeers().first { $0.id == other.id }?.state
  }
}

@Suite("Nearby friend use case")
struct NearbyFriendUseCaseTests {
  let relay = MockNearbyRelayRepository()
  let clock = TestClock()

  private func pair() async -> (Phone, Phone) {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)
    await alice.sees(bob, clock: clock)
    await bob.sees(alice, clock: clock)
    return (alice, bob)
  }

  // MARK: - Discovery

  @Test func resolvesVerifiedPeersAndEvictsStaleOnes() async {
    let (alice, bob) = await pair()
    #expect(await alice.useCase.visiblePeers() == [NearbyPeer(id: bob.id, name: "Bob")])

    clock.advance(11)
    await alice.useCase.tick()
    #expect(await alice.useCase.visiblePeers().isEmpty)
  }

  @Test func reenteringPhoneReplacesItsOldBubble() async throws {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)
    let carol = await Phone.make(name: "Carol", code: "CAR789", relay: relay, clock: clock)
    await alice.sees(bob, clock: clock)
    await alice.sees(carol, clock: clock)

    // Bob leaves Add Friends and comes straight back: same app launch, new session.
    await bob.useCase.stop()
    let bobAgain = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock, useCase: bob.useCase)
    #expect(bobAgain.id != bob.id)
    await alice.sees(bobAgain, clock: clock)

    #expect(await alice.useCase.visiblePeers().map(\.id) == [bobAgain.id, carol.id])

    // Still one Bob once the old session would have been evicted.
    clock.advance(11)
    await alice.sees(bobAgain, clock: clock)
    await alice.sees(carol, clock: clock)
    #expect(await alice.useCase.visiblePeers().map(\.name) == ["Bob", "Carol"])
  }

  @Test func differentLaunchesWithTheSameNameStaySeparate() async {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)
    let otherBob = await Phone.make(name: "Bob", code: "BOB999", relay: relay, clock: clock)
    await alice.sees(bob, clock: clock)
    await alice.sees(otherBob, clock: clock)
    #expect(await alice.useCase.visiblePeers().map(\.id) == [bob.id, otherBob.id])
  }

  @Test func addedStateCarriesOverWhenPeerReenters() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    try await alice.receive()
    try await bob.receive()
    #expect(await alice.state(of: bob) == .added)

    await bob.useCase.stop()
    let bobAgain = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock, useCase: bob.useCase)
    await alice.sees(bobAgain, clock: clock)
    #expect(await alice.useCase.visiblePeers() == [NearbyPeer(id: bobAgain.id, name: "Bob", state: .added)])
  }

  @Test func hidesFarAwayPeers() async {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    let near = await Phone.make(name: "Near", code: "NEAR11", relay: relay, clock: clock)
    let far = await Phone.make(name: "Far", code: "FARR33", relay: relay, clock: clock)
    await alice.sees(near, rssi: -45, clock: clock)
    await alice.sees(far, rssi: -95, clock: clock)
    #expect(await alice.useCase.visiblePeers().map(\.name) == ["Near"])
  }

  @Test func keepsFirstSeenOrderWhenSignalChanges() async {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    let first = await Phone.make(name: "First", code: "FRST11", relay: relay, clock: clock)
    let second = await Phone.make(name: "Second", code: "SCND22", relay: relay, clock: clock)
    let third = await Phone.make(name: "Third", code: "THRD33", relay: relay, clock: clock)
    // Heard in this order but resolved in one batch, weakest first.
    await alice.useCase.ingest(BeaconSighting(token: first.session.token, rssi: -75, seenAt: clock.now))
    clock.advance(0.1)
    await alice.useCase.ingest(BeaconSighting(token: second.session.token, rssi: -60, seenAt: clock.now))
    clock.advance(0.1)
    await alice.useCase.ingest(BeaconSighting(token: third.session.token, rssi: -40, seenAt: clock.now))
    await alice.useCase.tick()
    #expect(await alice.useCase.visiblePeers().map(\.name) == ["First", "Second", "Third"])

    // Signals swap around; the bubbles stay put.
    for _ in 0..<5 {
      await alice.useCase.ingest(BeaconSighting(token: first.session.token, rssi: -35, seenAt: clock.now))
      await alice.useCase.ingest(BeaconSighting(token: third.session.token, rssi: -78, seenAt: clock.now))
    }
    await alice.useCase.tick()
    #expect(await alice.useCase.visiblePeers().map(\.name) == ["First", "Second", "Third"])

    // Someone who drifts out of range disappears without moving the others…
    for _ in 0..<5 {
      await alice.useCase.ingest(BeaconSighting(token: second.session.token, rssi: -100, seenAt: clock.now))
    }
    #expect(await alice.useCase.visiblePeers().map(\.name) == ["First", "Third"])

    // …and comes back to the same slot, even after being evicted entirely.
    clock.advance(11)
    await alice.useCase.tick()
    #expect(await alice.useCase.visiblePeers().isEmpty)
    for peer in [third, second, first] {
      await alice.useCase.ingest(BeaconSighting(token: peer.session.token, rssi: -50, seenAt: clock.now))
    }
    await alice.useCase.tick()
    #expect(await alice.useCase.visiblePeers().map(\.name) == ["First", "Second", "Third"])
  }

  @Test func smoothsRSSI() async {
    let (alice, bob) = await pair()
    // One weak reading only pulls the average to -50·0.7 + -100·0.3 = -65.
    await alice.useCase.ingest(BeaconSighting(token: bob.session.token, rssi: -100, seenAt: clock.now))
    #expect(await alice.useCase.visiblePeers().count == 1)
  }

  @Test func ignoresOwnTokenAndRejectsForgedPresence() async throws {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    await alice.useCase.ingest(BeaconSighting(token: alice.session.token, rssi: -40, seenAt: clock.now))

    // A presence published under someone's token but with another key.
    let victim = NearbySession()
    let attacker = NearbySession()
    let card = NearbyPresenceCard(pub: attacker.publicKeyX963.base64URLEncodedString(), name: "Mallory")
    await relay.setPresence(try NearbyCrypto.sealPresence(card, session: victim), for: victim.lookupId)
    await alice.useCase.ingest(BeaconSighting(token: victim.token, rssi: -40, seenAt: clock.now))
    await alice.useCase.tick()

    #expect(await alice.useCase.visiblePeers().isEmpty)
    // Rejected tokens aren't looked up again.
    let lookups = await relay.batchGetCallCount
    await alice.useCase.tick()
    #expect(await relay.batchGetCallCount == lookups)
  }

  // MARK: - Exchange

  @Test func requestAcceptConfirmAddsBothWays() async throws {
    let (alice, bob) = await pair()

    await alice.useCase.request(bob.id)
    #expect(await alice.state(of: bob) == .requested)

    try await bob.receive()
    #expect(await bob.state(of: alice) == .incoming)

    await bob.useCase.accept(alice.id)
    #expect(await bob.state(of: alice) == .adding)

    try await alice.receive()
    #expect(alice.friends.addedCodes == ["BOB123"])
    #expect(await alice.state(of: bob) == .added)

    try await bob.receive()
    #expect(bob.friends.addedCodes == ["ALI456"])
    #expect(await bob.state(of: alice) == .added)
  }

  @Test func simultaneousRequestsMakeOneFriendship() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    await bob.useCase.request(alice.id)

    // Each treats the other's request as an accept, then the accepts cross.
    try await alice.receive()
    try await bob.receive()
    try await alice.receive()
    try await bob.receive()

    #expect(alice.friends.addedCodes == ["BOB123"])
    #expect(bob.friends.addedCodes == ["ALI456"])
    #expect(await alice.state(of: bob) == .added)
    #expect(await bob.state(of: alice) == .added)
  }

  @Test func declineShowsDeclinedAndCanAskAgain() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.decline(alice.id)
    #expect(await bob.state(of: alice) == .idle)

    try await alice.receive()
    #expect(await alice.state(of: bob) == .declined)
    #expect(alice.friends.addedCodes.isEmpty)

    // Tapping again sends a fresh request, which Bob sees as a new one.
    await alice.useCase.request(bob.id)
    #expect(await alice.state(of: bob) == .requested)
    try await bob.receive()
    #expect(await bob.state(of: alice) == .incoming)
  }

  @Test func declinedPeerStillLeavesWhenOutOfRange() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.decline(alice.id)
    try await alice.receive()
    #expect(await alice.state(of: bob) == .declined)

    clock.advance(11)
    await alice.useCase.tick()
    #expect(await alice.useCase.visiblePeers().isEmpty)
  }

  @Test func declinedRequesterCanStillBeAskedByThem() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.decline(alice.id)
    try await alice.receive()

    await bob.useCase.request(alice.id)
    try await alice.receive()
    #expect(await alice.state(of: bob) == .incoming)
  }

  @Test func cancelWithdrawsIncomingRequest() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await alice.useCase.cancel(bob.id)
    #expect(await alice.state(of: bob) == .idle)

    try await bob.receive()
    #expect(await bob.state(of: alice) == .idle)
  }

  @Test func unansweredRequestTimesOutAndCancels() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()

    clock.advance(61)
    // Keep Bob in range so only the request times out.
    await alice.useCase.ingest(BeaconSighting(token: bob.session.token, rssi: -50, seenAt: clock.now))
    await alice.useCase.tick()
    #expect(await alice.state(of: bob) == .idle)

    try await bob.receive()
    #expect(await bob.state(of: alice) == .idle)
  }

  @Test func unansweredIncomingRequestExpiresAfterSixtySeconds() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    #expect(await bob.state(of: alice) == .incoming)

    clock.advance(59)
    await bob.useCase.ingest(BeaconSighting(token: alice.session.token, rssi: -50, seenAt: clock.now))
    await bob.useCase.tick()
    #expect(await bob.state(of: alice) == .incoming)

    clock.advance(2)
    await bob.useCase.ingest(BeaconSighting(token: alice.session.token, rssi: -50, seenAt: clock.now))
    await bob.useCase.tick()
    #expect(await bob.state(of: alice) == .idle)
  }

  @Test func incomingRequestLapsesWhenRequesterLeaves() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()

    clock.advance(11)
    await bob.useCase.tick()
    #expect(await bob.useCase.exchanges[alice.session.token]?.state == .idle)
    // A late accept tap does nothing.
    await bob.useCase.accept(alice.id)
    #expect(bob.friends.addedCodes.isEmpty)
  }

  @Test func relayOnlyRequesterKeepsFullSixtySeconds() async throws {
    let alice = await Phone.make(name: "Alice", code: "ALI456", relay: relay, clock: clock)
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)
    // Alice hears Bob, but Bob never hears Alice over BLE.
    await alice.sees(bob, clock: clock)
    await alice.useCase.request(bob.id)
    try await bob.receive()
    #expect(await bob.state(of: alice) == .incoming)

    clock.advance(30)
    await bob.useCase.tick()
    #expect(await bob.state(of: alice) == .incoming)

    clock.advance(31)
    await bob.useCase.tick()
    #expect(await bob.useCase.exchanges[alice.session.token]?.state == .idle)
  }

  @Test func requesterConfirmsBeforeAdding() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    let postedBeforeAccept = await relay.posted.count
    // If adding fails, the confirm must already be on its way to Bob.
    alice.friends.addFriendResult = .failure(NetworkError.serverError(statusCode: 500))
    try await alice.receive()
    #expect(alice.friends.addedCodes == ["BOB123"])
    #expect(await alice.state(of: bob) == .failed)
    let confirm = try #require(await relay.posted.last)
    #expect(await relay.posted.count == postedBeforeAccept + 1)
    #expect(confirm.lookupId == bob.session.lookupId)

    try await bob.receive()
    #expect(bob.friends.addedCodes == ["ALI456"])
  }

  @Test func missingConfirmFailsThenRetrySendsFreshRequest() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    #expect(await bob.state(of: alice) == .adding)

    // Alice never reads the accept, so no confirm arrives.
    clock.advance(61)
    await bob.useCase.ingest(BeaconSighting(token: alice.session.token, rssi: -50, seenAt: clock.now))
    await bob.useCase.tick()
    #expect(await bob.state(of: alice) == .failed)

    await bob.useCase.request(alice.id)
    #expect(await bob.state(of: alice) == .requested)
    let request = try #require(await relay.posted.last)
    #expect(request.lookupId == alice.session.lookupId)
    #expect(bob.friends.addedCodes.isEmpty)
  }

  @Test func acceptRetriesCodeFetchOnce() async throws {
    let (alice, bob) = await pair()
    // The session-start load failed; the retry on accept succeeds.
    bob.friends.fetchMyCodeResult = .failure(NetworkError.notFound)
    await bob.useCase.loadMyCode()
    bob.friends.fetchMyCodeResult = .success("BOB123")
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    #expect(bob.friends.fetchMyCodeCallCount == 2)
    #expect(await bob.state(of: alice) == .adding)

    try await alice.receive()
    #expect(alice.friends.addedCodes == ["BOB123"])
  }

  @Test func acceptFailsWhenCodeRetryFails() async throws {
    let (alice, bob) = await pair()
    bob.friends.fetchMyCodeResult = .failure(NetworkError.notFound)
    await bob.useCase.loadMyCode()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    #expect(bob.friends.fetchMyCodeCallCount == 2)
    #expect(await bob.state(of: alice) == .failed)
    // Nothing went out without a code.
    #expect(await relay.posted.allSatisfy { $0.lookupId != alice.session.lookupId })

    // Failed is retryable: tapping sends a fresh request.
    bob.friends.fetchMyCodeResult = .success("BOB123")
    await bob.useCase.request(alice.id)
    #expect(await bob.state(of: alice) == .requested)
  }

  @Test func confirmFailsWhenCodeRetryFailsThenResumes() async throws {
    let (alice, bob) = await pair()
    alice.friends.fetchMyCodeResult = .failure(NetworkError.notFound)
    await alice.useCase.loadMyCode()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)

    try await alice.receive()
    #expect(alice.friends.fetchMyCodeCallCount == 2)
    #expect(await alice.state(of: bob) == .failed)
    #expect(alice.friends.addedCodes.isEmpty)

    // Nothing was sent to Bob: no confirm without a code, and no add yet.
    #expect(await relay.posted.last?.lookupId == alice.session.lookupId)

    // Retrying with the code now available confirms and adds without asking again.
    alice.friends.fetchMyCodeResult = .success("ALI456")
    let postedBeforeRetry = await relay.posted.count
    await alice.useCase.request(bob.id)
    #expect(await relay.posted.count == postedBeforeRetry + 1)
    #expect(await relay.posted.last?.lookupId == bob.session.lookupId)
    #expect(await alice.state(of: bob) == .added)
    #expect(alice.friends.addedCodes == ["BOB123"])
    try await bob.receive()
    #expect(bob.friends.addedCodes == ["ALI456"])
  }

  @Test func duplicateMessagesAreIgnored() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)

    // Replay Bob's accept into Alice's mailbox before she reads it.
    let accept = try #require(await relay.posted.last)
    await relay.inject(header: accept.header, body: accept.body, to: accept.lookupId)
    try await alice.receive()
    #expect(alice.friends.addedCodes == ["BOB123"])
  }

  @Test func staleMessagesAreDropped() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    // Bob's clock is 11 minutes ahead by the time he reads it.
    clock.advance(11 * 60)
    await bob.useCase.ingest(BeaconSighting(token: alice.session.token, rssi: -50, seenAt: clock.now))
    try await bob.receive()
    #expect(await bob.state(of: alice) == .idle)
  }

  @Test func tamperedMessagesAreDropped() async throws {
    let (alice, bob) = await pair()
    let key = try NearbyCrypto.pairKey(
      privateKey: alice.session.privateKey,
      peerPublicKey: bob.session.privateKey.publicKey,
      myToken: alice.session.token,
      peerToken: bob.session.token
    )
    let header = try NearbyCrypto.seal(
      alice.session.token,
      key: bob.session.presenceKey,
      aad: NearbyCrypto.headerAAD(recipientLookupId: bob.session.lookupId)
    )
    let request = NearbyMessageBody(type: .request, sentAt: Int64(clock.now.timeIntervalSince1970 * 1000))
    var body = try NearbyCrypto.seal(
      JSONEncoder().encode(request),
      key: key,
      aad: NearbyCrypto.bodyAAD(recipientLookupId: bob.session.lookupId, senderToken: alice.session.token)
    )
    body[body.count - 1] ^= 0x01
    await relay.inject(header: header, body: body, to: bob.session.lookupId)
    try await bob.receive()
    #expect(await bob.state(of: alice) == .idle)
  }

  @Test func alreadyFriendsCountsAsAdded() async throws {
    // OTL answers 2xx when the friendship already exists, so it looks the same.
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    try await alice.receive()
    #expect(await alice.state(of: bob) == .added)
  }

  @Test func failedAddCanBeRetried() async throws {
    let (alice, bob) = await pair()
    alice.friends.addFriendResult = .failure(NetworkError.serverError(statusCode: 500))
    await alice.useCase.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(alice.id)
    try await alice.receive()
    #expect(await alice.state(of: bob) == .failed)

    alice.friends.addFriendResult = .success(())
    let messagesBefore = await relay.posted.count
    await alice.useCase.request(bob.id)
    #expect(await alice.state(of: bob) == .added)
    // Retrying re-adds the stored code instead of asking Bob again.
    #expect(alice.friends.addedCodes == ["BOB123", "BOB123"])
    #expect(await relay.posted.count == messagesBefore)
  }

  // MARK: - Stop

  @Test func stopCancelsRequestsAndDeletesPresence() async throws {
    let (alice, bob) = await pair()
    await alice.useCase.request(bob.id)
    try await bob.receive()

    await alice.useCase.stop()
    #expect(await relay.deletedLookupIds == [alice.session.lookupId])
    #expect(await relay.presences[alice.session.lookupId] == nil)
    #expect(await alice.useCase.session == nil)

    try await bob.receive()
    #expect(await bob.state(of: alice) == .idle)
  }

  // MARK: - Presence expiry

  /// A phone with a beacon, prepared but not yet published.
  private func beaconPhone(name: String = "Alice", code: String = "ALI456") async -> (NearbyFriendUseCase, MockNearbyBeaconService, MockFriendUseCase) {
    let beacon = MockNearbyBeaconService()
    let friends = MockFriendUseCase()
    friends.fetchMyCodeResult = .success(code)
    let useCase = NearbyFriendUseCase(
      beaconService: beacon,
      relayRepository: relay,
      friendUseCase: friends,
      crashlyticsService: nil,
      now: { [clock] in clock.now }
    )
    await useCase.prepare(displayName: name)
    return (useCase, beacon, friends)
  }

  @Test func advertisesOnlyAfterFirstPublish() async throws {
    let (useCase, beacon, _) = await beaconPhone()
    await relay.setFailPutPresence(true)
    #expect(await useCase.publishPresence() == false)
    #expect(beacon.advertisedTokens.isEmpty)
    #expect(await useCase.isAdvertising == false)

    await relay.setFailPutPresence(false)
    #expect(await useCase.publishPresence())
    let token = try #require(await useCase.session?.token)
    #expect(beacon.advertisedTokens == [token])
    #expect(await relay.presences[NearbyCrypto.lookupId(for: token)] != nil)

    // Renewals don't restart the beacon.
    #expect(await useCase.publishPresence())
    #expect(beacon.advertisedTokens.count == 1)
  }

  @Test func freshPresenceIsNotRotated() async throws {
    let (useCase, beacon, _) = await beaconPhone()
    await useCase.publishPresence()
    let token = try #require(await useCase.session?.token)
    clock.advance(60)
    await useCase.tick()
    #expect(await useCase.session?.token == token)
    #expect(beacon.advertisedTokens == [token])
  }

  @Test func suspendedPastExpiryRotatesToANewSession() async throws {
    let (alice, beacon, _) = await beaconPhone()
    await alice.publishPresence()
    let oldToken = try #require(await alice.session?.token)
    let oldLookup = NearbyCrypto.lookupId(for: oldToken)

    // Bob was added before the app went to the background.
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)
    await alice.ingest(BeaconSighting(token: bob.session.token, rssi: -50, seenAt: clock.now))
    await alice.tick()
    await alice.request(bob.id)
    try await bob.receive()
    await bob.useCase.accept(oldToken.hexString)
    try await alice.pollOnce(wait: 0)
    #expect(await alice.visiblePeers().first?.state == .added)

    // Suspended with no renewals until just inside the safety margin.
    clock.advance(300 - 30)
    await alice.tick()

    let newToken = try #require(await alice.session?.token)
    #expect(newToken != oldToken)
    #expect(await relay.deletedLookupIds.contains(oldLookup))
    #expect(await relay.presences[oldLookup] == nil)
    #expect(await alice.exchanges[bob.session.token]?.state == .added)

    // Not advertised until the new presence is published.
    #expect(beacon.currentToken == nil)
    #expect(await alice.isAdvertising == false)
    #expect(await alice.publishPresence())
    #expect(beacon.currentToken == newToken)
    #expect(beacon.advertisedTokens == [oldToken, newToken])
    #expect(await relay.presences[NearbyCrypto.lookupId(for: newToken)] != nil)
  }

  @Test func rotationDropsInFlightExchangesAndCancelsOurRequests() async throws {
    let (alice, _, _) = await beaconPhone()
    await alice.publishPresence()
    let oldToken = try #require(await alice.session?.token)
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)
    await alice.ingest(BeaconSighting(token: bob.session.token, rssi: -50, seenAt: clock.now))
    await alice.tick()
    await alice.request(bob.id)
    try await bob.receive()
    #expect(await bob.useCase.visiblePeers().map(\.state) == [.incoming])

    clock.advance(300)
    await alice.tick()
    #expect(await alice.session?.token != oldToken)
    #expect(await alice.exchanges[bob.session.token] == nil)

    // Bob got the withdrawal, sent from the old session.
    try await bob.receive()
    #expect(await bob.useCase.visiblePeers().allSatisfy { $0.state != .incoming })
  }

  @Test func failingRenewalsStopAdvertisingUntilAPublishSucceeds() async throws {
    let (useCase, beacon, _) = await beaconPhone()
    await useCase.publishPresence()
    let oldToken = try #require(await useCase.session?.token)
    #expect(beacon.currentToken == oldToken)

    // The network goes away; renewals fail until the presence lapses.
    await relay.setFailPutPresence(true)
    for _ in 0..<5 {
      clock.advance(60)
      #expect(await useCase.publishPresence() == false)
      await useCase.tick()
    }
    #expect(beacon.currentToken == nil)
    let newToken = try #require(await useCase.session?.token)
    #expect(newToken != oldToken)

    // Still offline: retries don't advertise and don't rotate again.
    clock.advance(5)
    #expect(await useCase.publishPresence() == false)
    await useCase.tick()
    #expect(await useCase.session?.token == newToken)
    #expect(beacon.currentToken == nil)

    await relay.setFailPutPresence(false)
    #expect(await useCase.publishPresence())
    #expect(beacon.currentToken == newToken)
  }

  @Test func streamPublishesPeersAndStopsOnCancel() async throws {
    let beacon = MockNearbyBeaconService()
    let friends = MockFriendUseCase()
    var configuration = NearbyFriendUseCase.Configuration()
    configuration.tickInterval = 0.05
    configuration.pollWait = 0
    let useCase = NearbyFriendUseCase(
      beaconService: beacon,
      relayRepository: relay,
      friendUseCase: friends,
      crashlyticsService: nil,
      configuration: configuration,
      now: { Date() }
    )
    let bob = await Phone.make(name: "Bob", code: "BOB123", relay: relay, clock: clock)

    let stream = useCase.start(displayName: "Alice")
    let consumer = Task { () -> [NearbyPeer]? in
      for await peers in stream where !peers.isEmpty { return peers }
      return nil
    }
    // Wait for the beacon to start, then let Bob be heard.
    for _ in 0..<100 where beacon.advertisedTokens.isEmpty {
      try await Task.sleep(for: .milliseconds(10))
    }
    let token = try #require(beacon.advertisedTokens.first)
    #expect(await relay.presences[NearbyCrypto.lookupId(for: token)] != nil)
    beacon.emit(BeaconSighting(token: bob.session.token, rssi: -50, seenAt: Date()))

    let peers = await consumer.value
    #expect(peers == [NearbyPeer(id: bob.id, name: "Bob")])

    await useCase.stop()
    #expect(beacon.stopCallCount >= 1)
    #expect(await relay.deletedLookupIds.contains(NearbyCrypto.lookupId(for: token)))
  }
}
