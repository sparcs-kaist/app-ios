//
//  IncomingRequestCard.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import BuddyDomain

/// Pending requests stacked like notifications: the front one is interactive
/// and the next few peek out behind it, so it's clear more are waiting.
/// Answering the front card brings the next one forward.
struct IncomingRequestStack: View {
  let peers: [NearbyPeer]
  let onAccept: (NearbyPeer) -> Void
  let onDecline: (NearbyPeer) -> Void

  /// Cards drawn, including the front one; more than this only shows in the count.
  private let maxVisibleCards = 3
  /// How far each card behind peeks out above the one in front of it.
  private let peekOffset: CGFloat = 10

  var body: some View {
    ZStack(alignment: .top) {
      ForEach(Array(peers.prefix(maxVisibleCards).enumerated()), id: \.element.id) { depth, peer in
        IncomingRequestCard(
          peer: peer,
          remainingCount: depth == 0 ? peers.count - 1 : 0,
          isFront: depth == 0,
          onAccept: { onAccept(peer) },
          onDecline: { onDecline(peer) }
        )
        .scaleEffect(1 - CGFloat(depth) * 0.05, anchor: .top)
        .offset(y: -CGFloat(depth) * peekOffset)
        .zIndex(Double(-depth))
        .allowsHitTesting(depth == 0)
        .transition(.blurReplace)
      }
    }
    // Room for the cards peeking out above the front one.
    .padding(.top, CGFloat(min(peers.count, maxVisibleCards) - 1) * peekOffset)
    .sensoryFeedback(.impact, trigger: peers.count) { oldValue, newValue in newValue > oldValue }
  }
}

/// Floats above the bottom bar when someone nearby asks to add you.
struct IncomingRequestCard: View {
  let peer: NearbyPeer
  /// Requests waiting behind this one; shown as a badge on the front card.
  var remainingCount = 0
  /// Cards behind the front one keep their size but hide their content, so
  /// only their glass edge shows.
  var isFront = true
  let onAccept: () -> Void
  let onDecline: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 12) {
        NearbyInitialsCircle(name: peer.name, diameter: 44)

        VStack(alignment: .leading, spacing: 2) {
          Text(peer.name)
            .font(.headline)
            .lineLimit(1)

          Text("wants to add you as a friend", bundle: .module)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 0)

        if remainingCount > 0 {
          Text(verbatim: "+\(remainingCount)")
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white.opacity(0.15), in: .capsule)
            .contentTransition(.numericText())
            .accessibilityLabel(Text("\(remainingCount) more requests", bundle: .module))
        }
      }

      HStack(spacing: 12) {
        Button(action: onDecline) {
          Text("Decline", bundle: .module)
        }
        .buttonStyle(.glass)

        Button(action: onAccept) {
          Text("Accept", bundle: .module)
        }
        .buttonStyle(.glassProminent)
      }
      .buttonSizing(.flexible)
      .controlSize(.large)
    }
    .opacity(isFront ? 1 : 0)
    .padding(20)
    .glassEffect(.regular, in: .rect(cornerRadius: 28))
    .accessibilityHidden(!isFront)
  }
}
