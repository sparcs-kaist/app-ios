//
//  MockNearbyRelayRepository.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import BuddyDomain

/// An in-memory relay. Several use cases can share one to talk to each other,
/// which is how the tests play two phones against each other.
public actor MockNearbyRelayRepository: NearbyRelayRepositoryProtocol {
  public struct Posted: Sendable, Equatable {
    public let lookupId: Data
    public let header: Data
    public let body: Data
  }

  public private(set) var presences: [Data: Data] = [:]
  public private(set) var owners: [Data: Data] = [:]
  public private(set) var mailboxes: [Data: [RelayMessage]] = [:]
  public private(set) var posted: [Posted] = []
  public private(set) var deletedLookupIds: [Data] = []
  public private(set) var batchGetCallCount = 0
  private var nextMessageId = 1

  public var failPutPresence = false
  public var failPostMessage = false
  public private(set) var putPresenceCallCount = 0

  public func setFailPutPresence(_ fails: Bool) {
    failPutPresence = fails
  }

  public init() { }

  public func setFailPostMessage(_ fails: Bool) {
    failPostMessage = fails
  }

  /// Plants a presence without going through `putPresence`, e.g. a forged one.
  public func setPresence(_ blob: Data, for lookupId: Data) {
    presences[lookupId] = blob
  }

  /// Plants a raw message, e.g. a replayed or tampered one.
  public func inject(header: Data, body: Data, to lookupId: Data) {
    mailboxes[lookupId, default: []].append(
      RelayMessage(id: String(nextMessageId), header: header, body: body)
    )
    nextMessageId += 1
  }

  public func putPresence(lookupId: Data, blob: Data, ownerSecret: Data) async throws -> Date {
    putPresenceCallCount += 1
    if failPutPresence { throw TestError.testFailure }
    if let owner = owners[lookupId], owner != ownerSecret { throw NetworkError.serverError(statusCode: 409) }
    owners[lookupId] = ownerSecret
    presences[lookupId] = blob
    return Date().addingTimeInterval(300)
  }

  public func batchGet(lookupIds: [Data]) async throws -> [Data: Data] {
    batchGetCallCount += 1
    return presences.filter { lookupIds.contains($0.key) }
  }

  public func deletePresence(lookupId: Data, ownerSecret: Data) async throws {
    deletedLookupIds.append(lookupId)
    presences[lookupId] = nil
    owners[lookupId] = nil
    mailboxes[lookupId] = nil
  }

  public func postMessage(to lookupId: Data, header: Data, body: Data) async throws {
    if failPostMessage { throw TestError.testFailure }
    guard presences[lookupId] != nil else { throw NetworkError.notFound }
    posted.append(Posted(lookupId: lookupId, header: header, body: body))
    inject(header: header, body: body, to: lookupId)
  }

  public func pollMessages(lookupId: Data, ownerSecret: Data, after: String?, wait: Int) async throws -> RelayMessagesPage {
    guard presences[lookupId] != nil else { throw NetworkError.notFound }
    let acked = after.flatMap(Int.init) ?? 0
    var mailbox = mailboxes[lookupId, default: []]
    mailbox.removeAll { (Int($0.id) ?? 0) <= acked }
    mailboxes[lookupId] = mailbox
    return RelayMessagesPage(messages: mailbox, cursor: mailbox.last?.id ?? String(acked))
  }
}
