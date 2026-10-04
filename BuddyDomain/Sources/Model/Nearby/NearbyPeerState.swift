//
//  NearbyPeerState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

/// Where a nearby peer is in the request/accept exchange.
public enum NearbyPeerState: Sendable, Equatable, Hashable {
  /// Discovered; nothing sent yet.
  case idle
  /// We asked to add them and are waiting for their answer.
  case requested
  /// They said no to our request. Tapping asks again.
  case declined
  /// They asked to add us.
  case incoming
  /// Both sides agreed; friend codes are being exchanged and added.
  case adding
  case added
  /// The exchange or the add failed; can be retried.
  case failed
}
