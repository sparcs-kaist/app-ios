//
//  NearbyFriendUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import CryptoKit
import os
import BuddyDomain

private let logger = Logger(subsystem: "org.sparcs.soap", category: "NearbyFriendUseCase")

/// Runs one Add Friends nearby session: advertises our token, resolves the
/// tokens we hear into verified people, and walks each of them through the
/// request → accept → confirm exchange (nearby friends plan §2.6). Once both
/// sides have the other's OTL friend code, each adds it through
/// `FriendUseCase`, which creates the friendship in both directions.
public actor NearbyFriendUseCase: NearbyFriendUseCaseProtocol {
  public struct Configuration: Sendable {
    /// Peers quieter than this (smoothed) aren't shown.
    public var rssiThreshold: Double = -80
    /// Weight of a new reading in the RSSI moving average.
    public var rssiSmoothing: Double = 0.3
    public var evictAfter: TimeInterval = 10
    public var tickInterval: TimeInterval = 1
    public var renewInterval: TimeInterval = 60
    /// Rotate to a new session once our presence is this close to expiring
    /// without having been renewed, e.g. after the app was suspended.
    public var expiryMargin: TimeInterval = 30
    /// Assumed presence lifetime when the relay's expiry can't be used.
    public var presenceTTL: TimeInterval = 300
    public var retryPublishInterval: TimeInterval = 5
    public var pollWait: Int = 20
    public var maxPollBackoff: TimeInterval = 30
    /// An unanswered request (ours or theirs), or an accept whose confirm
    /// never comes, gives up after this long.
    public var requestTimeout: TimeInterval = 60
    /// Messages sent further than this from our clock are dropped.
    public var maxMessageSkew: TimeInterval = 600
    public var maxBatchSize: Int = 32

    public init() { }
  }

  /// A peer whose presence we fetched and verified.
  struct ResolvedPeer {
    let token: Data
    let lookupId: Data
    let name: String
    let publicKey: P256.KeyAgreement.PublicKey
    /// Position in the grid: peers keep the order they first appeared in.
    let order: Int
    /// The peer's per-launch device ID, if its card carries one.
    let device: String?
  }

  /// Identifies this app launch on presence cards; see `NearbyPresenceCard.device`.
  /// Kept for the life of the process, so it outlives any one session.
  public static let launchDeviceID = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) }).base64URLEncodedString()

  struct Sighting {
    var rssi: Double
    var lastSeen: Date
    let firstSeen: Date
  }

  /// Where the exchange with one peer stands.
  struct Exchange {
    var state: NearbyPeerState = .idle
    /// When `state` last changed; drives the timeouts.
    var since: Date
    var requestMsgId: String?
    var incomingRequestId: String?
    /// Whether they have our friend code (sent in an accept or a confirm).
    var sentMyCode = false
    /// Their accept still needs our confirm; kept so a retry can send it.
    var acceptToConfirm: String?
    var theirCode: String?
  }

  private let beaconService: NearbyBeaconServiceProtocol?
  private let relayRepository: NearbyRelayRepositoryProtocol
  private let friendUseCase: FriendUseCaseProtocol?
  private let crashlyticsService: CrashlyticsServiceProtocol?
  private let configuration: Configuration
  private let now: @Sendable () -> Date
  private let deviceID: String

  // Session state; all reset by `stop()`.
  private(set) var session: NearbySession?
  private var displayName = ""
  private var myCode: String?
  private var continuation: AsyncStream<[NearbyPeer]>.Continuation?
  /// Identifies the stream returned by the latest `start`, so ending an old
  /// one can't stop a newer session.
  private var streamID: UUID?
  private var tasks: [Task<Void, Never>] = []
  /// Bumped on every start and stop so work from an old session can tell.
  private var generation = 0
  private var sightings: [Data: Sighting] = [:]
  private(set) var resolved: [Data: ResolvedPeer] = [:]
  /// Tokens whose presence failed to decrypt or verify; never retried.
  private var rejected: Set<Data> = []
  /// Missing presences are retried with backoff.
  private var retryAt: [Data: (date: Date, attempts: Int)] = [:]
  private var pairKeys: [Data: SymmetricKey] = [:]
  private(set) var exchanges: [Data: Exchange] = [:]
  private var seenMessageIds: Set<String> = []
  private var nextOrder = 0
  private var cursor: String?
  private var lastEmitted: [NearbyPeer]?
  /// When our current presence lapses on the relay (on our clock); `nil`
  /// until the session's first successful publish.
  private(set) var presenceExpiresAt: Date?
  private(set) var presencePublishedAt: Date?
  /// Whether the beacon is advertising the current session's token.
  private(set) var isAdvertising = false
  private var isRotating = false

  public init(
    beaconService: NearbyBeaconServiceProtocol?,
    relayRepository: NearbyRelayRepositoryProtocol,
    friendUseCase: FriendUseCaseProtocol?,
    crashlyticsService: CrashlyticsServiceProtocol?,
    configuration: Configuration = Configuration(),
    deviceID: String = NearbyFriendUseCase.launchDeviceID,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.beaconService = beaconService
    self.relayRepository = relayRepository
    self.friendUseCase = friendUseCase
    self.crashlyticsService = crashlyticsService
    self.configuration = configuration
    self.deviceID = deviceID
    self.now = now
  }

  // MARK: - Lifecycle

  public nonisolated func start(displayName: String) -> AsyncStream<[NearbyPeer]> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: [NearbyPeer].self,
      bufferingPolicy: .bufferingNewest(1)
    )
    let id = UUID()
    let runner = Task { await self.run(displayName: displayName, continuation: continuation, id: id) }
    continuation.onTermination = { _ in
      runner.cancel()
      Task { await self.streamEnded(id) }
    }
    return stream
  }

  private func run(displayName: String, continuation: AsyncStream<[NearbyPeer]>.Continuation, id: UUID) async {
    guard !Task.isCancelled else {
      continuation.finish()
      return
    }
    let session = await prepare(displayName: displayName)
    guard self.session?.token == session.token else {
      continuation.finish()
      return
    }
    guard !Task.isCancelled else {
      await stop()
      continuation.finish()
      return
    }
    self.continuation = continuation
    streamID = id
    lastEmitted = nil
    publish()

    startLoops()
  }

  /// Starts the background loops for the current session. The beacon isn't
  /// among them: it starts once the presence is first published, so nobody
  /// hears a token they can't look up.
  private func startLoops() {
    let generation = generation
    tasks = [
      Task { await self.loadMyCode() },
      Task { await self.presenceLoop(generation) },
      Task { await self.tickLoop(generation) },
      Task { await self.pollLoop(generation) }
    ]
  }

  /// Starts a fresh session without its background loops. `start` builds on
  /// this; tests call it directly and drive the loops' steps by hand.
  @discardableResult
  func prepare(displayName: String) async -> NearbySession {
    if session != nil { await stop() }
    generation += 1
    let session = NearbySession()
    self.session = session
    self.displayName = NearbyPresenceCard.truncatedName(displayName)
    return session
  }

  private func streamEnded(_ id: UUID) async {
    guard streamID == id else { return }
    await stop()
  }

  public func stop() async {
    generation += 1
    streamID = nil
    tasks.forEach { $0.cancel() }
    tasks = []
    stopAdvertising()
    presenceExpiresAt = nil
    presencePublishedAt = nil
    continuation?.finish()
    continuation = nil

    guard let session else { return }
    let waiting = exchanges.compactMap { token, exchange in
      exchange.state == .requested ? resolved[token] : nil
    }
    self.session = nil
    myCode = nil
    sightings = [:]
    resolved = [:]
    rejected = []
    retryAt = [:]
    pairKeys = [:]
    exchanges = [:]
    seenMessageIds = []
    nextOrder = 0
    cursor = nil
    lastEmitted = nil

    // Best effort: tell people we asked that we've gone, then disappear.
    for peer in waiting {
      try? await send(.cancel, to: peer, session: session)
    }
    try? await relayRepository.deletePresence(lookupId: session.lookupId, ownerSecret: session.ownerSecret)
  }

  // MARK: - Actions

  public func request(_ peerID: NearbyPeer.ID) async {
    guard let token = Data(hexString: peerID), let peer = resolved[token], let session else { return }
    let exchange = exchanges[token] ?? Exchange(since: now())

    switch exchange.state {
    case .failed where exchange.theirCode != nil:
      // We already have their code; finish confirming and adding it.
      await complete(token: token)
    case .idle, .declined, .failed:
      let body = NearbyMessageBody(type: .request, sentAt: timestamp())
      exchanges[token] = Exchange(state: .requested, since: now(), requestMsgId: body.msgId)
      publish()
      do {
        try await send(body, to: peer, session: session)
      } catch {
        record(error, operation: "request")
        if exchanges[token]?.state == .requested { setState(.failed, for: token) }
      }
    case .requested, .incoming, .adding, .added:
      break
    }
  }

  public func cancel(_ peerID: NearbyPeer.ID) async {
    guard let token = Data(hexString: peerID), let peer = resolved[token], let session,
          exchanges[token]?.state == .requested else { return }
    setState(.idle, for: token)
    try? await send(.cancel, to: peer, session: session)
  }

  public func accept(_ peerID: NearbyPeer.ID) async {
    guard let token = Data(hexString: peerID), exchanges[token]?.state == .incoming else { return }
    await sendAccept(to: token, inReplyTo: exchanges[token]?.incomingRequestId)
  }

  public func decline(_ peerID: NearbyPeer.ID) async {
    guard let token = Data(hexString: peerID), let peer = resolved[token], let session,
          let exchange = exchanges[token], exchange.state == .incoming else { return }
    setState(.idle, for: token)
    let body = NearbyMessageBody(type: .decline, sentAt: timestamp(), inReplyTo: exchange.incomingRequestId)
    try? await send(body, to: peer, session: session)
  }

  // MARK: - Loops

  /// Loads our OTL friend code at the start of a session. Without it we can
  /// still find people and ask them; `ensureMyCode` tries once more when an
  /// exchange actually needs it.
  func loadMyCode() async {
    guard let friendUseCase, let session else { return }
    do {
      let code = FriendCode.normalized(try await friendUseCase.fetchMyCode())
      if self.session?.token == session.token { myCode = code }
    } catch {
      logger.error("Couldn't load friend code: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func presenceLoop(_ generation: Int) async {
    while generation == self.generation, !Task.isCancelled {
      let published = await publishPresence()
      let delay = published ? configuration.renewInterval : configuration.retryPublishInterval
      guard await Self.sleep(delay) else { return }
    }
  }

  private func beaconLoop(_ stream: AsyncThrowingStream<BeaconSighting, Error>, generation: Int) async {
    do {
      for try await sighting in stream {
        guard generation == self.generation else { return }
        ingest(sighting)
      }
    } catch {
      logger.error("Beacon stopped: \(error.localizedDescription, privacy: .public)")
    }
  }

  /// Starts advertising the current session's token, once its presence is
  /// published. Scanning starts with it.
  private func startAdvertisingIfNeeded() {
    guard !isAdvertising, presenceExpiresAt != nil, let session, let beaconService else { return }
    isAdvertising = true
    let stream = beaconService.start(advertising: session.token)
    let generation = generation
    tasks.append(Task { await self.beaconLoop(stream, generation: generation) })
  }

  private func stopAdvertising() {
    guard isAdvertising else { return }
    isAdvertising = false
    beaconService?.stop()
  }

  private func tickLoop(_ generation: Int) async {
    while generation == self.generation, !Task.isCancelled {
      await tick()
      guard await Self.sleep(configuration.tickInterval) else { return }
    }
  }

  private func pollLoop(_ generation: Int) async {
    var backoff: TimeInterval = 1
    while generation == self.generation, !Task.isCancelled {
      do {
        try await pollOnce(wait: configuration.pollWait)
        backoff = 1
      } catch NetworkError.notFound {
        // Our presence lapsed (e.g. the relay restarted); publish it again.
        _ = await publishPresence()
        guard await Self.sleep(backoff) else { return }
      } catch {
        guard !Task.isCancelled else { return }
        logger.error("Mailbox poll failed: \(error.localizedDescription, privacy: .public)")
        guard await Self.sleep(backoff) else { return }
        backoff = min(backoff * 2, configuration.maxPollBackoff)
      }
    }
  }

  // MARK: - Steps

  @discardableResult
  func publishPresence() async -> Bool {
    guard let session else { return false }
    do {
      let card = NearbyPresenceCard(
        pub: session.publicKeyX963.base64URLEncodedString(),
        name: displayName,
        device: deviceID
      )
      let blob = try NearbyCrypto.sealPresence(card, session: session)
      let serverExpiry = try await relayRepository.putPresence(
        lookupId: session.lookupId,
        blob: blob,
        ownerSecret: session.ownerSecret
      )
      // A rotation may have replaced the session while we waited.
      guard self.session?.token == session.token else { return false }
      recordPublished(serverExpiry: serverExpiry)
      startAdvertisingIfNeeded()
      return true
    } catch {
      record(error, operation: "putPresence")
      return false
    }
  }

  /// Remembers when the presence lapses, on our own clock: the relay's expiry
  /// is turned into a remaining lifetime so a skewed device clock can't make
  /// every tick look expired (or never expired).
  private func recordPublished(serverExpiry: Date) {
    let date = now()
    let remaining = serverExpiry.timeIntervalSince(Date())
    let lifetime = (remaining > 0 && remaining <= configuration.presenceTTL) ? remaining : configuration.presenceTTL
    presencePublishedAt = date
    presenceExpiresAt = date.addingTimeInterval(lifetime)
  }

  /// Whether our presence is expired, or about to be, without a renewal:
  /// the app was suspended or renewals kept failing.
  var isPresenceStale: Bool {
    guard let presenceExpiresAt else { return false }
    return now() >= presenceExpiresAt.addingTimeInterval(-configuration.expiryMargin)
  }

  /// Replaces a session whose presence has lapsed with a brand-new one: new
  /// key and token, published before it's advertised. The old token is never
  /// advertised again. Finished adds carry over; anything in flight was tied
  /// to the old session and goes back to idle.
  func rotateSession() async {
    guard let old = session else { return }
    stopAdvertising()
    generation += 1
    let generation = generation
    tasks.forEach { $0.cancel() }
    tasks = []

    let waiting = exchanges.compactMap { token, exchange in
      exchange.state == .requested ? resolved[token] : nil
    }
    let fresh = NearbySession()
    session = fresh
    presenceExpiresAt = nil
    presencePublishedAt = nil
    pairKeys = [:]
    seenMessageIds = []
    cursor = nil
    exchanges = exchanges.filter { $0.value.state == .added }
    publish()

    // Best effort, signed with the old keys: tell people we asked that we've
    // gone, then take the old presence down.
    for peer in waiting {
      try? await send(.cancel, to: peer, session: old)
    }
    try? await relayRepository.deletePresence(lookupId: old.lookupId, ownerSecret: old.ownerSecret)
    guard generation == self.generation, session?.token == fresh.token else { return }
    if continuation != nil { startLoops() }
  }

  /// Rotates the session if its presence lapsed. Runs every tick, which also
  /// covers the first tick after the app resumes from suspension.
  func checkPresenceExpiry() async {
    guard isPresenceStale, !isRotating else { return }
    logger.info("Presence lapsed without renewal; rotating the nearby session")
    isRotating = true
    // Not a child of the tick loop: rotating cancels that loop, and the
    // cleanup requests must still go out.
    await Task.detached { await self.rotateSession() }.value
    isRotating = false
  }

  /// Records one BLE sighting.
  func ingest(_ sighting: BeaconSighting) {
    guard let session, sighting.token != session.token,
          sighting.token.count == NearbyCrypto.tokenLength else { return }
    let reading = Double(sighting.rssi)
    if var existing = sightings[sighting.token] {
      existing.rssi = configuration.rssiSmoothing * reading + (1 - configuration.rssiSmoothing) * existing.rssi
      existing.lastSeen = sighting.seenAt
      sightings[sighting.token] = existing
    } else {
      sightings[sighting.token] = Sighting(rssi: reading, lastSeen: sighting.seenAt, firstSeen: sighting.seenAt)
    }
    publish()
  }

  /// Evicts stale sightings, resolves new nearby tokens, applies timeouts and
  /// publishes the peer list. Runs once a second.
  func tick() async {
    await checkPresenceExpiry()
    let date = now()
    let evicted = sightings.keys.filter { date.timeIntervalSince(sightings[$0]!.lastSeen) > configuration.evictAfter }
    evicted.forEach { sightings[$0] = nil }
    // A request from someone who has walked away (or closed the screen) lapses.
    for token in evicted where exchanges[token]?.state == .incoming {
      setState(.idle, for: token)
    }

    let pending = sightings
      .filter { token, sighting in
        sighting.rssi >= configuration.rssiThreshold
          && resolved[token] == nil
          && !rejected.contains(token)
          && (retryAt[token].map { $0.date <= date } ?? true)
      }
      .sorted { $0.value.rssi > $1.value.rssi }
      .prefix(configuration.maxBatchSize)
      .map(\.key)
    if !pending.isEmpty {
      await resolve(Array(pending))
    }

    await applyTimeouts()
    publish()
  }

  /// Reads the mailbox once, acknowledging what was read before.
  func pollOnce(wait: Int) async throws {
    guard let session else { return }
    let page = try await relayRepository.pollMessages(
      lookupId: session.lookupId,
      ownerSecret: session.ownerSecret,
      after: cursor,
      wait: wait
    )
    guard self.session?.token == session.token else { return }
    cursor = page.cursor
    for message in page.messages {
      await handle(message, session: session)
    }
    publish()
  }

  // MARK: - Resolution

  private func resolve(_ tokens: [Data]) async {
    let lookupIds = Dictionary(uniqueKeysWithValues: tokens.map { (NearbyCrypto.lookupId(for: $0), $0) })
    let blobs: [Data: Data]
    do {
      blobs = try await relayRepository.batchGet(lookupIds: Array(lookupIds.keys))
    } catch {
      logger.error("Presence lookup failed: \(error.localizedDescription, privacy: .public)")
      return
    }
    let date = now()
    let ordered = lookupIds.sorted { lhs, rhs in
      let left = sightings[lhs.value]?.firstSeen ?? date
      let right = sightings[rhs.value]?.firstSeen ?? date
      return left != right ? left < right : lhs.value.hexString < rhs.value.hexString
    }
    for (lookupId, token) in ordered where resolved[token] == nil {
      guard let blob = blobs[lookupId] else {
        // Not published yet, or already gone: try again a little later.
        let attempts = (retryAt[token]?.attempts ?? 0) + 1
        retryAt[token] = (date.addingTimeInterval(min(pow(2, Double(attempts - 1)), 30)), attempts)
        continue
      }
      do {
        let (card, publicKey) = try NearbyCrypto.openPresence(blob, token: token)
        let previous = card.device.flatMap { device in
          resolved.values.first { $0.device == device && $0.token != token }
        }
        resolved[token] = ResolvedPeer(
          token: token,
          lookupId: lookupId,
          name: card.name,
          publicKey: publicKey,
          order: previous?.order ?? nextOrder,
          device: card.device
        )
        if let previous {
          replace(previous.token, with: token)
        } else {
          nextOrder += 1
        }
        retryAt[token] = nil
      } catch {
        // Someone else's beacon on our prefix, or a substituted key.
        rejected.insert(token)
      }
    }
  }

  /// The same phone came back with a new session: its new token takes over
  /// the old bubble's place. Only a finished add carries over; anything in
  /// flight was tied to the old session, which the peer no longer has.
  private func replace(_ oldToken: Data, with newToken: Data) {
    if exchanges[oldToken]?.state == .added, exchanges[newToken] == nil {
      var exchange = Exchange(since: now())
      exchange.state = .added
      exchanges[newToken] = exchange
    }
    resolved[oldToken] = nil
    sightings[oldToken] = nil
    exchanges[oldToken] = nil
    pairKeys[oldToken] = nil
    retryAt[oldToken] = nil
  }

  // MARK: - Messages

  private func handle(_ message: RelayMessage, session: NearbySession) async {
    guard let senderToken = try? NearbyCrypto.open(
      message.header,
      key: session.presenceKey,
      aad: NearbyCrypto.headerAAD(recipientLookupId: session.lookupId)
    ), senderToken.count == NearbyCrypto.tokenLength, senderToken != session.token else { return }

    if resolved[senderToken] == nil, !rejected.contains(senderToken) {
      await resolve([senderToken])
    }
    guard let peer = resolved[senderToken],
          let key = try? pairKey(for: peer, session: session),
          let plaintext = try? NearbyCrypto.open(
            message.body,
            key: key,
            aad: NearbyCrypto.bodyAAD(recipientLookupId: session.lookupId, senderToken: senderToken)
          ),
          let body = try? JSONDecoder().decode(NearbyMessageBody.self, from: plaintext),
          body.v == 1 else { return }

    guard !seenMessageIds.contains(body.msgId) else { return }
    seenMessageIds.insert(body.msgId)
    let sentAt = Date(timeIntervalSince1970: TimeInterval(body.sentAt) / 1000)
    guard abs(sentAt.timeIntervalSince(now())) <= configuration.maxMessageSkew,
          let type = body.messageType else { return }

    await apply(type, body: body, from: senderToken)
  }

  /// The per-peer state machine (plan §2.6).
  private func apply(_ type: NearbyMessageType, body: NearbyMessageBody, from token: Data) async {
    let exchange = exchanges[token] ?? Exchange(since: now())

    switch (type, exchange.state) {
    case (.request, .requested):
      // We tapped each other at the same time: treat theirs as accepting ours.
      await sendAccept(to: token, inReplyTo: body.msgId)
    case (.request, .idle), (.request, .declined), (.request, .failed):
      exchanges[token] = Exchange(state: .incoming, since: now(), incomingRequestId: body.msgId)
    case (.request, .incoming):
      exchanges[token]?.incomingRequestId = body.msgId

    case (.accept, .requested), (.accept, .adding):
      guard let code = body.friendCode.flatMap(FriendCode.normalized),
            exchanges[token]?.theirCode == nil else { return }
      exchanges[token]?.state = .adding
      exchanges[token]?.since = now()
      exchanges[token]?.theirCode = code
      if exchanges[token]?.sentMyCode == false {
        exchanges[token]?.acceptToConfirm = body.msgId
      }
      publish()
      await complete(token: token)

    case (.confirm, .adding):
      guard let code = body.friendCode.flatMap(FriendCode.normalized), exchanges[token]?.theirCode == nil else { return }
      exchanges[token]?.theirCode = code
      await addFriend(token: token)

    case (.decline, .requested):
      setState(.declined, for: token)
    case (.cancel, .incoming):
      setState(.idle, for: token)

    default:
      // Late or out-of-order messages, e.g. an accept after we withdrew.
      break
    }
  }

  private func sendAccept(to token: Data, inReplyTo requestId: String?) async {
    guard let peer = resolved[token], let session else { return }
    guard let myCode = await ensureMyCode() else {
      // Accepting means handing over our code, so it can't happen without one.
      setState(.failed, for: token)
      return
    }
    let body = NearbyMessageBody(type: .accept, sentAt: timestamp(), inReplyTo: requestId, friendCode: myCode)
    var exchange = exchanges[token] ?? Exchange(since: now())
    exchange.state = .adding
    exchange.since = now()
    exchange.sentMyCode = true
    exchanges[token] = exchange
    publish()
    do {
      try await send(body, to: peer, session: session)
    } catch {
      record(error, operation: "accept")
      if exchanges[token]?.state == .adding, exchanges[token]?.theirCode == nil {
        setState(.failed, for: token)
      }
    }
  }

  /// Sends our confirm if they still need our code, then adds theirs. Fails
  /// the peer (retryable) if our code can't be loaded.
  private func complete(token: Data) async {
    guard var exchange = exchanges[token], exchange.theirCode != nil else { return }
    if !exchange.sentMyCode {
      guard let myCode = await ensureMyCode() else {
        setState(.failed, for: token)
        return
      }
      guard let peer = resolved[token], let session else { return }
      exchange = exchanges[token] ?? exchange
      exchange.sentMyCode = true
      let replyTo = exchange.acceptToConfirm
      exchange.acceptToConfirm = nil
      exchanges[token] = exchange
      let confirm = NearbyMessageBody(type: .confirm, sentAt: timestamp(), inReplyTo: replyTo, friendCode: myCode)
      try? await send(confirm, to: peer, session: session)
    }
    await addFriend(token: token)
  }

  /// Our OTL friend code, fetched once more if the first attempt failed.
  private func ensureMyCode() async -> String? {
    if let myCode { return myCode }
    guard let friendUseCase, let session else { return nil }
    let code = (try? await friendUseCase.fetchMyCode()).flatMap(FriendCode.normalized)
    if self.session?.token == session.token { myCode = code }
    return code
  }

  private func addFriend(token: Data) async {
    guard let code = exchanges[token]?.theirCode else { return }
    setState(.adding, for: token)
    do {
      try await friendUseCase?.addFriend(code: code)
      // A 2xx covers "already friends" too: OTL adds both directions idempotently.
      if exchanges[token] != nil { setState(.added, for: token) }
    } catch {
      if exchanges[token] != nil { setState(.failed, for: token) }
    }
  }

  private func applyTimeouts() async {
    let date = now()
    for (token, exchange) in exchanges {
      let age = date.timeIntervalSince(exchange.since)
      switch exchange.state {
      case .requested where age > configuration.requestTimeout:
        setState(.idle, for: token)
        if let peer = resolved[token], let session {
          try? await send(.cancel, to: peer, session: session)
        }
      case .incoming where age > configuration.requestTimeout:
        setState(.idle, for: token)
      case .adding where exchange.theirCode == nil && age > configuration.requestTimeout:
        // We accepted but their confirm never came.
        setState(.failed, for: token)
      default:
        break
      }
    }
  }

  // MARK: - Sending

  private func send(_ type: NearbyMessageType, to peer: ResolvedPeer, session: NearbySession) async throws {
    try await send(NearbyMessageBody(type: type, sentAt: timestamp()), to: peer, session: session)
  }

  private func send(_ body: NearbyMessageBody, to peer: ResolvedPeer, session: NearbySession) async throws {
    let header = try NearbyCrypto.seal(
      session.token,
      key: NearbyCrypto.presenceKey(for: peer.token),
      aad: NearbyCrypto.headerAAD(recipientLookupId: peer.lookupId)
    )
    let sealedBody = try NearbyCrypto.seal(
      JSONEncoder().encode(body),
      key: pairKey(for: peer, session: session),
      aad: NearbyCrypto.bodyAAD(recipientLookupId: peer.lookupId, senderToken: session.token)
    )
    try await relayRepository.postMessage(to: peer.lookupId, header: header, body: sealedBody)
  }

  private func pairKey(for peer: ResolvedPeer, session: NearbySession) throws -> SymmetricKey {
    if self.session?.token == session.token, let key = pairKeys[peer.token] { return key }
    let key = try NearbyCrypto.pairKey(
      privateKey: session.privateKey,
      peerPublicKey: peer.publicKey,
      myToken: session.token,
      peerToken: peer.token
    )
    if self.session?.token == session.token { pairKeys[peer.token] = key }
    return key
  }

  // MARK: - Publishing

  /// The peers to show: verified, and either close enough or mid-exchange.
  /// Bubbles keep the order they first appeared in; signal strength only
  /// decides whether they're shown, so the grid never reshuffles.
  func visiblePeers() -> [NearbyPeer] {
    resolved.values
      .filter { peer in
        let state = exchanges[peer.token]?.state ?? .idle
        let inRange = sightings[peer.token].map { $0.rssi >= configuration.rssiThreshold } ?? false
        // A decline is settled, like idle: it leaves with the peer.
        return inRange || (state != .idle && state != .declined)
      }
      .sorted { $0.order < $1.order }
      .map { peer in
        NearbyPeer(id: peer.token.hexString, name: peer.name, state: exchanges[peer.token]?.state ?? .idle)
      }
  }

  private func publish() {
    guard let continuation else { return }
    let peers = visiblePeers()
    guard peers != lastEmitted else { return }
    lastEmitted = peers
    continuation.yield(peers)
  }

  // MARK: - Helpers

  private func setState(_ state: NearbyPeerState, for token: Data) {
    var exchange = exchanges[token] ?? Exchange(since: now())
    exchange.state = state
    exchange.since = now()
    if state == .idle {
      exchange = Exchange(since: now())
    }
    exchanges[token] = exchange
    publish()
  }

  private func timestamp() -> Int64 {
    Int64((now().timeIntervalSince1970 * 1000).rounded())
  }

  private func record(_ error: Error, operation: String) {
    crashlyticsService?.record(
      error: error,
      context: CrashContext(feature: "NearbyFriends", metadata: ["operation": operation])
    )
  }

  /// Sleeps, returning `false` if the task was cancelled meanwhile.
  private static func sleep(_ seconds: TimeInterval) async -> Bool {
    do {
      try await Task.sleep(for: .seconds(seconds))
      return true
    } catch {
      return false
    }
  }
}
