//
//  NearbyPeer.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

/// Someone discovered nearby on the Add Friends screen.
public struct NearbyPeer: Identifiable, Sendable, Equatable, Hashable {
  /// The peer's BLE session token, hex-encoded. Only stable for one session.
  public let id: String
  public let name: String
  public var state: NearbyPeerState

  public init(id: String, name: String, state: NearbyPeerState = .idle) {
    self.id = id
    self.name = name
    self.state = state
  }
}
