//
//  NearbyPeerBubble.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import BuddyDomain

/// One person in the nearby grid: a glass circle with their initials, their
/// name, and a status line that blur-replaces as the exchange progresses.
struct NearbyPeerBubble: View {
  let peer: NearbyPeer
  let glassNamespace: Namespace.ID
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 8) {
        NearbyInitialsCircle(name: peer.name)
          // Blurred behind the spinner/checkmark so the two don't overlap.
          .blur(radius: isBusyOrDone ? 6 : 0)
          .clipShape(.circle)
          .overlay { NearbyPeerStateOverlay(state: peer.state) }
          .glassEffect(glass, in: .circle)
          .glassEffectID(peer.id, in: glassNamespace)
          .phaseAnimator([false, true], trigger: peer.state == .incoming) { content, isPulsed in
            content.scaleEffect(peer.state == .incoming && isPulsed ? 1.08 : 1)
          } animation: { _ in
            .easeInOut(duration: 0.6)
          }

        Text(peer.name)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary)
          .lineLimit(1)

        NearbyPeerStatusLabel(state: peer.state)
      }
      .frame(maxWidth: .infinity)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .disabled(peer.state == .adding || peer.state == .added)
    .sensoryFeedback(.success, trigger: peer.state) { _, newValue in newValue == .added }
    .accessibilityElement(children: .combine)
    .accessibilityHint(accessibilityHint)
  }

  private var isBusyOrDone: Bool {
    peer.state == .requested || peer.state == .adding || peer.state == .added
  }

  private var glass: Glass {
    switch peer.state {
    case .added:
      .regular.tint(.green.opacity(0.35))
    case .incoming:
      .regular.tint(.pink.opacity(0.3)).interactive()
    case .failed:
      .regular.tint(.red.opacity(0.3)).interactive()
    default:
      .regular.interactive()
    }
  }

  private var accessibilityHint: Text {
    switch peer.state {
    case .idle, .declined:
      Text("Sends a friend request", bundle: .module)
    case .requested:
      Text("Cancels your request", bundle: .module)
    case .incoming:
      Text("Accepts their request", bundle: .module)
    case .failed:
      Text("Tries again", bundle: .module)
    case .adding, .added:
      Text(verbatim: "")
    }
  }
}

/// Spinner while waiting, checkmark once added; nothing otherwise.
struct NearbyPeerStateOverlay: View {
  let state: NearbyPeerState

  var body: some View {
    Group {
      switch state {
      case .requested, .adding:
        Circle()
          .fill(.black.opacity(0.2))
          .overlay { ProgressView().tint(.white) }
      case .added:
        Circle()
          .fill(.black.opacity(0.2))
          .overlay {
            Image(systemName: "checkmark")
              .font(.title2.weight(.bold))
              .foregroundStyle(.white)
          }
      case .idle, .declined, .incoming, .failed:
        Color.clear
      }
    }
    .transition(.blurReplace)
  }
}

struct NearbyPeerStatusLabel: View {
  let state: NearbyPeerState

  var body: some View {
    Group {
      switch state {
      case .idle:
        Text("Tap to add", bundle: .module)
          .foregroundStyle(.secondary)
      case .requested:
        Text("Waiting…", bundle: .module)
          .foregroundStyle(.secondary)
      case .declined:
        Text("Declined", bundle: .module)
          .foregroundStyle(.secondary)
      case .incoming:
        Text("Wants to add you", bundle: .module)
          .foregroundStyle(.pink)
      case .adding:
        Text("Adding…", bundle: .module)
          .foregroundStyle(.secondary)
      case .added:
        Label {
          Text("Added", bundle: .module)
        } icon: {
          Image(systemName: "checkmark.circle.fill")
        }
        .foregroundStyle(.green)
      case .failed:
        Text("Tap to retry", bundle: .module)
          .foregroundStyle(.red)
      }
    }
    .font(.caption)
    .lineLimit(2)
    .multilineTextAlignment(.center)
    .transition(.blurReplace)
  }
}
