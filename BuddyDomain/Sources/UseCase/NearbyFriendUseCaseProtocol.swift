//
//  NearbyFriendUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

public protocol NearbyFriendUseCaseProtocol: Sendable {
  /// Starts a session and emits the sorted peer list until the stream is
  /// cancelled or `stop()` is called.
  func start(displayName: String) -> AsyncStream<[NearbyPeer]>
  func request(_ peerID: NearbyPeer.ID) async
  /// Withdraws our pending request.
  func cancel(_ peerID: NearbyPeer.ID) async
  func accept(_ peerID: NearbyPeer.ID) async
  func decline(_ peerID: NearbyPeer.ID) async
  func stop() async
}
