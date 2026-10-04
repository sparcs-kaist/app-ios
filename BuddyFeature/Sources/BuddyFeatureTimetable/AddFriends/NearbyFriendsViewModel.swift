//
//  NearbyFriendsViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

/// Drives the nearby section of Add Friends: follows Bluetooth availability,
/// runs a nearby session while the screen is visible, and forwards taps to it.
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
    let incoming = peers.filter { $0.state == .incoming }
    return incomingOrder.compactMap { id in incoming.first { $0.id == id } }
  }

  /// Bumped when someone is added, so the friends list can reload.
  private(set) var addedCount = 0

  /// Set once the person taps Allow; keys the view's availability task, so
  /// the system prompt only ever appears in response to that tap.
  private(set) var hasRequestedPermission = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.nearbyFriendUseCase) private var nearbyFriendUseCase: NearbyFriendUseCaseProtocol?
  @ObservationIgnored @Injected(\.nearbyBeaconService) private var beaconService: NearbyBeaconServiceProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.analyticsService) private var analyticsService: AnalyticsServiceProtocol?

  /// Previews pass `true` so a fixed state stays put and taps change it locally.
  @ObservationIgnored private let isPreview: Bool
  /// Incoming request IDs in arrival order; the use case sorts by distance.
  @ObservationIgnored private var incomingOrder: [NearbyPeer.ID] = []

  init(viewState: NearbyFriendsViewState? = nil, isPreview: Bool = false) {
    self.isPreview = isPreview
    self.viewState = viewState ?? .unavailable(.permissionRequired)
  }

  // MARK: - Discovery

  /// Asks for Bluetooth, which shows the system prompt the first time.
  func grantPermission() {
    guard !isPreview else {
      viewState = .scanning(peers: [])
      return
    }
    hasRequestedPermission = true
  }

  /// Follows Bluetooth availability for as long as the calling task lives.
  /// Until the person taps Allow it doesn't touch Bluetooth, because starting
  /// to observe is what shows the system prompt.
  func runAvailability() async {
    guard !isPreview else { return }
    guard let beaconService else {
      viewState = .unavailable(.unsupported)
      return
    }
    if beaconService.authorization == .notDetermined, !hasRequestedPermission {
      viewState = .unavailable(.permissionRequired)
      return
    }
    for await authorization in beaconService.authorizationUpdates() where authorization != .notDetermined {
      apply(authorization)
    }
  }

  /// Runs a nearby session for as long as the calling task lives, so tie it to
  /// the view's `.task(id:)` together with `isScanning` and the scene phase.
  func runDiscovery() async {
    guard !isPreview, isScanning, let nearbyFriendUseCase else { return }
    let displayName = await self.displayName()
    guard !Task.isCancelled else { return }
    analyticsService?.logEvent(AddFriendsViewEvent.nearbyStarted)
    let stream = nearbyFriendUseCase.start(displayName: displayName)
    for await peers in stream {
      update(peers)
    }
    // Leaving here (cancellation or Bluetooth going away) ends the session.
    await nearbyFriendUseCase.stop()
  }

  // MARK: - Actions

  func tap(_ peer: NearbyPeer) {
    switch peer.state {
    case .idle, .declined, .failed:
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
    guard peer.state == .idle || peer.state == .declined || peer.state == .failed else { return }
    perform(peer, preview: .requested, event: .requestSent) { await $0.request(peer.id) }
  }

  func cancel(_ peer: NearbyPeer) {
    guard peer.state == .requested else { return }
    perform(peer, preview: .idle, event: nil) { await $0.cancel(peer.id) }
  }

  func accept(_ peer: NearbyPeer) {
    guard peer.state == .incoming else { return }
    perform(peer, preview: .added, event: .requestAccepted) { await $0.accept(peer.id) }
  }

  func decline(_ peer: NearbyPeer) {
    guard peer.state == .incoming else { return }
    perform(peer, preview: .idle, event: .requestDeclined) { await $0.decline(peer.id) }
  }

  // MARK: - Helpers

  private func perform(
    _ peer: NearbyPeer,
    preview state: NearbyPeerState,
    event: AddFriendsViewEvent?,
    _ action: @escaping @Sendable (NearbyFriendUseCaseProtocol) async -> Void
  ) {
    if let event { analyticsService?.logEvent(event) }
    guard !isPreview else {
      setState(state, for: peer.id)
      return
    }
    guard let nearbyFriendUseCase else { return }
    Task { await action(nearbyFriendUseCase) }
  }

  private func apply(_ authorization: NearbyBluetoothAuthorization) {
    if let reason = authorization.unavailableReason {
      viewState = .unavailable(reason)
    } else if !isScanning {
      viewState = .scanning(peers: [])
    }
  }

  private func update(_ newPeers: [NearbyPeer]) {
    guard isScanning else { return }
    let previous = Dictionary(uniqueKeysWithValues: peers.map { ($0.id, $0.state) })
    for peer in newPeers where peer.state == .added && previous[peer.id] != .added {
      addedCount += 1
      analyticsService?.logEvent(AddFriendsViewEvent.friendAdded)
    }
    let incoming = Set(newPeers.filter { $0.state == .incoming }.map(\.id))
    incomingOrder.removeAll { !incoming.contains($0) }
    incomingOrder += newPeers.map(\.id).filter { incoming.contains($0) && !incomingOrder.contains($0) }
    viewState = .scanning(peers: newPeers)
  }

  /// The OTL name, which is what friends see in their list once added.
  private func displayName() async -> String {
    guard let userUseCase else { return "" }
    if let name = await userUseCase.otlUser?.name, !name.isEmpty { return name }
    try? await userUseCase.fetchOTLUser()
    if let name = await userUseCase.otlUser?.name, !name.isEmpty { return name }
    return await userUseCase.feedUser?.nickname ?? ""
  }

  private func setState(_ state: NearbyPeerState, for id: NearbyPeer.ID) {
    guard case .scanning(var peers) = viewState,
          let index = peers.firstIndex(where: { $0.id == id }) else { return }
    peers[index].state = state
    update(peers)
  }
}
