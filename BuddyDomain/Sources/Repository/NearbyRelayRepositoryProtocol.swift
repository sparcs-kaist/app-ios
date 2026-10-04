//
//  NearbyRelayRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// The nearby relay only ever sees hashes and ciphertexts; see the nearby
/// friends plan for the protocol.
public protocol NearbyRelayRepositoryProtocol: Sendable {
  /// Creates or renews a presence and returns when it expires.
  func putPresence(lookupId: Data, blob: Data, ownerSecret: Data) async throws -> Date
  /// Returns the blob for each lookup ID that has a live presence.
  func batchGet(lookupIds: [Data]) async throws -> [Data: Data]
  func deletePresence(lookupId: Data, ownerSecret: Data) async throws
  func postMessage(to lookupId: Data, header: Data, body: Data) async throws
  /// Long-polls the mailbox, acknowledging everything up to `after`.
  func pollMessages(lookupId: Data, ownerSecret: Data, after: String?, wait: Int) async throws -> RelayMessagesPage
}
