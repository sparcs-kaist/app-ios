//
//  NearbyFriendsViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import Observation
import BuddyDomain

/// Drives the nearby section of Add Friends.
///
/// The BLE beacon and relay don't exist yet, so this simulates both sides with
/// mock data: people appear one by one, one of them sends a request, and our
/// own requests are answered after a short delay. The public surface matches
/// what the real implementation will need, so the view won't change when it
/// arrives.
@MainActor
@Observable
final class NearbyFriendsViewModel {
  var viewState: NearbyFriendsViewState

  var peers: [NearbyPeer] {
    guard case .scanning(let peers) = viewState else { return [] }
    return peers
  }

  var isScanning: Bool {
    if case .scanning = viewState { true } else { false }
  }

  /// Pending requests, oldest first; the first is the front card of the stack.
  var incomingPeers: [NearbyPeer] {
    peers.filter { $0.state == .incoming }
  }

  /// Previews pass `false` so a fixed state stays put.
  @ObservationIgnored private let simulatesDiscovery: Bool
  @ObservationIgnored private var replyTasks: [NearbyPeer.ID: Task<Void, Never>] = [:]

  init(
    viewState: NearbyFriendsViewState = .unavailable(.permissionRequired),
    simulatesDiscovery: Bool = true
  ) {
    self.viewState = viewState
    self.simulatesDiscovery = simulatesDiscovery
  }

  // MARK: - Discovery

  /// Stands in for the Bluetooth permission prompt.
  func grantPermission() {
    viewState = .scanning(peers: [])
  }

  /// Runs for as long as the calling task lives, so tie it to the view's
  /// `.task(id:)`.
  func runDiscovery() async {
    guard simulatesDiscovery, isScanning else { return }

    for mock in NearbyPeer.mockList where !peers.contains(where: { $0.id == mock.id }) {
      guard await Self.pause(1.4) else { return }
      appendPeer(NearbyPeer(id: mock.id, name: mock.name))
    }

    // A few people tap us once the list has settled, so the stack fills up.
    for _ in 0..<3 {
      guard await Self.pause(2) else { return }
      if let peer = peers.last(where: { $0.state == .idle }) {
        setState(.incoming, for: peer.id)
      }
    }
  }

  // MARK: - Actions

  func tap(_ peer: NearbyPeer) {
    switch peer.state {
    case .idle, .failed:
      request(peer)
    case .requested:
      cancel(peer)
    case .incoming:
      accept(peer)
    case .adding, .added:
      break
    }
  }

  func request(_ peer: NearbyPeer) {
    guard peer.state == .idle || peer.state == .failed else { return }
    setState(.requested, for: peer.id)
    // Mock reply: they accept, then codes are exchanged and added.
    replyTasks[peer.id]?.cancel()
    replyTasks[peer.id] = Task { [weak self] in
      guard await Self.pause(2.5), let self, self.state(of: peer.id) == .requested else { return }
      self.setState(.adding, for: peer.id)
      guard await Self.pause(1.2), self.state(of: peer.id) == .adding else { return }
      self.setState(.added, for: peer.id)
    }
  }

  func cancel(_ peer: NearbyPeer) {
    guard peer.state == .requested else { return }
    replyTasks[peer.id]?.cancel()
    setState(.idle, for: peer.id)
  }

  func accept(_ peer: NearbyPeer) {
    guard peer.state == .incoming else { return }
    setState(.adding, for: peer.id)
    replyTasks[peer.id]?.cancel()
    replyTasks[peer.id] = Task { [weak self] in
      guard await Self.pause(1.2), let self, self.state(of: peer.id) == .adding else { return }
      self.setState(.added, for: peer.id)
    }
  }

  func decline(_ peer: NearbyPeer) {
    guard peer.state == .incoming else { return }
    setState(.idle, for: peer.id)
  }

  // MARK: - Helpers

  private func state(of id: NearbyPeer.ID) -> NearbyPeerState? {
    peers.first { $0.id == id }?.state
  }

  private func setState(_ state: NearbyPeerState, for id: NearbyPeer.ID) {
    guard case .scanning(var peers) = viewState,
          let index = peers.firstIndex(where: { $0.id == id }) else { return }
    peers[index].state = state
    viewState = .scanning(peers: peers)
  }

  private func appendPeer(_ peer: NearbyPeer) {
    guard case .scanning(var peers) = viewState else { return }
    peers.append(peer)
    viewState = .scanning(peers: peers)
  }

  /// Sleeps, returning `false` if the task was cancelled meanwhile.
  private static func pause(_ seconds: Double) async -> Bool {
    do {
      try await Task.sleep(for: .seconds(seconds))
      return true
    } catch {
      return false
    }
  }
}
