//
//  NearbyFriendsSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import BuddyDomain

/// The upper part of Add Friends: a fallback when discovery can't run, a radar
/// while nobody has been found, and the grid of people once someone has.
struct NearbyFriendsSection: View {
  let state: NearbyFriendsViewState
  let onGrantPermission: () -> Void
  let onOpenSettings: () -> Void
  let onTapPeer: (NearbyPeer) -> Void

  var body: some View {
    Group {
      switch state {
      case .unavailable(let reason):
        NearbyUnavailableView(
          reason: reason,
          onGrantPermission: onGrantPermission,
          onOpenSettings: onOpenSettings
        )
        .padding(.horizontal)
      case .scanning(let peers) where peers.isEmpty:
        NearbySearchingView()
          .padding(.horizontal)
      case .scanning(let peers):
        // Full width; it pads its own content so it can scroll edge to edge.
        NearbyPeersGrid(peers: peers, onTap: onTapPeer)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .transition(.blurReplace)
  }
}

/// Header row; the trailing waves animate while discovery runs.
struct NearbyHeader: View {
  let isScanning: Bool

  var body: some View {
    HStack {
      Text("Nearby Friends", bundle: .module)
        .font(.headline)
        .foregroundStyle(.primary.opacity(0.8))

      Spacer()

      if isScanning {
        Image(systemName: "dot.radiowaves.right")
          .foregroundStyle(.secondary)
          .symbolEffect(.variableColor.iterative, options: .repeating)
          .transition(.blurReplace)
          .accessibilityLabel(Text("Searching", bundle: .module))
      }
    }
  }
}

// MARK: - Grid

struct NearbyPeersGrid: View {
  let peers: [NearbyPeer]
  let onTap: (NearbyPeer) -> Void

  @Namespace private var glassNamespace

  // Top-aligned so a two-line status doesn't lift its circle above the row.
  private let columns = [GridItem(.adaptive(minimum: 96), spacing: 16, alignment: .top)]

  var body: some View {
    ScrollView {
      // Smaller than the gaps between circles so they don't merge at rest.
      GlassEffectContainer(spacing: 12) {
        LazyVGrid(columns: columns, spacing: 24) {
          ForEach(peers) { peer in
            NearbyPeerBubble(peer: peer, glassNamespace: glassNamespace) {
              onTap(peer)
            }
            .transition(.blurReplace)
          }
        }
        .padding(.vertical, 12)
      }
    }
    .contentMargins(.horizontal, 16, for: .scrollContent)
    // Fade rows out under the request cards rather than cutting them at a line.
    .scrollEdgeEffectStyle(.soft, for: .bottom)
    .scrollBounceBehavior(.basedOnSize)
    .scrollIndicators(.hidden)
  }
}

// MARK: - Searching

struct NearbySearchingView: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "dot.radiowaves.left.and.right")
        .font(.system(size: 44, weight: .semibold))
        .foregroundStyle(.white)
        .symbolEffect(.variableColor.iterative.reversing, options: .repeating)

      VStack(spacing: 6) {
        Text("Looking for Friends Nearby…", bundle: .module)
          .font(.headline)

        Text("Ask your friend to open Add Friends on their phone too.", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal)
    }
  }
}

// MARK: - Unavailable

struct NearbyUnavailableView: View {
  let reason: NearbyUnavailableReason
  let onGrantPermission: () -> Void
  let onOpenSettings: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: symbolName)
        .font(.system(size: 44, weight: .semibold))
        .foregroundStyle(.white)
        .symbolEffect(.bounce, value: reason)

      VStack(spacing: 6) {
        title
          .font(.headline)

        message
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal)

      switch reason {
      case .permissionRequired:
        Button(action: onGrantPermission) {
          Text("Allow Bluetooth", bundle: .module)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
      case .permissionDenied, .bluetoothOff:
        Button(action: onOpenSettings) {
          Text("Open Settings", bundle: .module)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
      case .unsupported:
        EmptyView()
      }
    }
  }

  private var symbolName: String {
    switch reason {
    case .permissionRequired: "antenna.radiowaves.left.and.right"
    case .permissionDenied: "hand.raised.fill"
    case .bluetoothOff: "antenna.radiowaves.left.and.right.slash"
    case .unsupported: "iphone.slash"
    }
  }

  private var title: Text {
    switch reason {
    case .permissionRequired:
      Text("Find Friends Nearby", bundle: .module)
    case .permissionDenied:
      Text("Bluetooth Access Needed", bundle: .module)
    case .bluetoothOff:
      Text("Bluetooth Is Off", bundle: .module)
    case .unsupported:
      Text("Not Available on This Device", bundle: .module)
    }
  }

  private var message: Text {
    switch reason {
    case .permissionRequired:
      Text("Allow Bluetooth so Buddy can find friends who have Add Friends open next to you.", bundle: .module)
    case .permissionDenied:
      Text("Buddy needs Bluetooth to find friends nearby. You can allow it in Settings.", bundle: .module)
    case .bluetoothOff:
      Text("Turn on Bluetooth in Control Centre or Settings to find friends nearby.", bundle: .module)
    case .unsupported:
      Text("This device can’t find friends nearby. You can still add friends with a code.", bundle: .module)
    }
  }
}
