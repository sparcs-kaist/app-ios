//
//  NearbyFriendsViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

public enum NearbyFriendsViewState: Equatable, Sendable {
  case unavailable(NearbyUnavailableReason)
  /// Discovery is running; `peers` is empty until someone is found.
  case scanning(peers: [NearbyPeer])
}
