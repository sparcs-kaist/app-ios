//
//  AddFriendsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/26/26.
//

import SwiftUI
import BuddyDomain

struct AddFriendsView: View {
  let viewModel: FriendsListViewModel
  @State private var nearbyViewModel: NearbyFriendsViewModel

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Environment(\.scenePhase) private var scenePhase

  @State private var isCodePromptPresented = false
  @State private var codeInput = ""

  init(
    viewModel: FriendsListViewModel,
    nearbyViewModel: NearbyFriendsViewModel = NearbyFriendsViewModel()
  ) {
    self.viewModel = viewModel
    self._nearbyViewModel = State(initialValue: nearbyViewModel)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        NearbyHeader(isScanning: nearbyViewModel.isScanning)
          .padding(.horizontal)

        NearbyFriendsSection(
          state: nearbyViewModel.viewState,
          onGrantPermission: { nearbyViewModel.grantPermission() },
          onOpenSettings: { openSettings() },
          onTapPeer: { nearbyViewModel.tap($0) }
        )
      }
      // Only top padding: the grid's scroll view has to reach the bar's safe
      // area and both screen edges, so it scrolls underneath the bar (with a
      // full-width edge effect) instead of being clipped just above it.
      // Horizontal padding is applied inside each piece instead.
      .padding(.top)
      .animation(.smooth, value: nearbyViewModel.viewState)
      .navigationTitle(Text("Add Friends", bundle: .module))
      // Inside the stack so the content above is inset by the bar instead of
      // running underneath it.
      .safeAreaBar(edge: .bottom) {
        VStack(spacing: 12) {
          if !nearbyViewModel.incomingPeers.isEmpty {
            IncomingRequestStack(
              peers: nearbyViewModel.incomingPeers,
              onAccept: { nearbyViewModel.accept($0) },
              onDecline: { nearbyViewModel.decline($0) }
            )
            .transition(.blurReplace)
          }

          MyFriendCodeView(code: viewModel.myCode, isUnavailable: viewModel.isMyCodeUnavailable)

          Button {
            codeInput = ""
            isCodePromptPresented = true
          } label: {
            Text("Add Friends via Code", bundle: .module)
          }
          .buttonSizing(.flexible)
          .controlSize(.large)
          .buttonStyle(.glass)
        }
        .scenePadding()
        .animation(.smooth, value: nearbyViewModel.incomingPeers)
      }
      // Also inside the stack; outside, its opaque background covers the gradient.
      .background {
        AnimatedMeshGradientView()
          .ignoresSafeArea()
      }
    }
    .task(id: nearbyViewModel.hasRequestedPermission) {
      await nearbyViewModel.runAvailability()
    }
    // Restarts whenever discovery starts or stops and is cancelled with the
    // sheet. Bluetooth only runs while the app is in the foreground.
    .task(id: DiscoveryKey(isScanning: nearbyViewModel.isScanning, isActive: scenePhase == .active)) {
      guard scenePhase == .active else { return }
      await nearbyViewModel.runDiscovery()
    }
    .onChange(of: nearbyViewModel.addedCount) {
      Task { await viewModel.load() }
    }
    .alert(Text("Add Friend", bundle: .module), isPresented: $isCodePromptPresented) {
      TextField(String(localized: "6-character code", bundle: .module), text: $codeInput)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .keyboardType(.asciiCapable)
      Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
      Button(String(localized: "Add", bundle: .module)) { submitCode() }
        .disabled(FriendCode.normalized(codeInput) == nil)
    } message: {
      Text("Enter your friend’s code to add them.", bundle: .module)
    }
    // Outside the alert: modifiers on its content aren't guaranteed to run, and
    // the field is the only thing writing to this state anyway.
    .onChange(of: codeInput) { _, newValue in
      let sanitized = sanitizedCode(newValue)
      if sanitized != codeInput { codeInput = sanitized }
    }
    // Scoped to this subtree; `.preferredColorScheme` would propagate to the
    // presenting window and briefly flash the parent dark while presenting.
    .environment(\.colorScheme, .dark)
  }

  private struct DiscoveryKey: Equatable {
    let isScanning: Bool
    let isActive: Bool
  }

  // MARK: - Actions

  private func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    openURL(url)
  }

  // MARK: - Code entry

  /// Friend codes are six upper-cased ASCII letters and digits, so anything else
  /// never reaches the field rather than being rejected after the fact.
  private func sanitizedCode(_ input: String) -> String {
    String(input.filter { $0.isASCII && ($0.isLetter || $0.isNumber) }.prefix(6)).uppercased()
  }

  private func submitCode() {
    guard let code = FriendCode.normalized(codeInput) else { return }
    Task {
      await viewModel.addFriend(code: code)
      dismiss()
    }
  }
}

struct AnimatedMeshGradientView: View {
  var body: some View {
    TimelineView(.animation) { timeline in
      let t = timeline.date.timeIntervalSince1970
      let redY = Self.columnTop(at: t, index: 0)
      let blueY = Self.columnTop(at: t, index: 1)
      let purpleY = Self.columnTop(at: t, index: 2)
      let blueX = Float(0.50 + sin(t * 0.55) * 0.12)
      let topX = Float(0.50 + sin(t * 0.48) * 0.10)
      let bottomX = Float(0.50 + sin(t * 0.51 + 0.8) * 0.12)

      let red = Color(red: 0.34, green: 0.08, blue: 0.24)
      let blue = Color(red: 0.07, green: 0.18, blue: 0.46)
      let purple = Color(red: 0.20, green: 0.07, blue: 0.44)

      // Top row stays dark; each column's colour fades into it above its
      // animated height.
      MeshGradient(
        width: 3,
        height: 3,
        points: [
          [0, 0], [topX, 0], [1, 0],
          [0, redY], [blueX, blueY], [1, purpleY],
          [0, 1], [bottomX, 1], [1, 1]
        ],
        colors: [
          Color(red: 0.01, green: 0.01, blue: 0.03),
          Color(red: 0.00, green: 0.00, blue: 0.02),
          Color(red: 0.01, green: 0.02, blue: 0.05),
          red, blue, purple,
          red, blue, purple
        ]
      )
    }
  }

  /// Each colour is a column rising from the bottom edge, and the columns
  /// take turns reaching for the top. Every column gets the same pulse offset
  /// by a third of a cycle; raising it to the 4th power keeps the pulse narrow,
  /// so only one column is tall at a time while the others rest low. A small
  /// slow wobble keeps the resting columns from looking frozen.
  private static func columnTop(at t: TimeInterval, index: Double) -> Float {
    let phase = index * 2 * .pi / 3
    let pulse = pow((1 + cos(t * 0.35 - phase)) / 2, 4)
    let wobble = sin(t * 0.27 + phase * 1.7) * 0.04
    return Float(0.80 - pulse * 0.55 + wobble)
  }
}

// MARK: - Previews

#if DEBUG
/// Builds the screen in a fixed nearby state. Taps still work, so each preview
/// can be driven by hand from there.
@MainActor
private func addFriendsPreview(
  _ state: NearbyFriendsViewState,
  myCode: String? = "ACD347",
  isMyCodeUnavailable: Bool = false
) -> AddFriendsView {
  let friendsViewModel = FriendsListViewModel()
  friendsViewModel.myCode = myCode
  friendsViewModel.isMyCodeUnavailable = isMyCodeUnavailable
  return AddFriendsView(
    viewModel: friendsViewModel,
    nearbyViewModel: NearbyFriendsViewModel(viewState: state, isPreview: true)
  )
}

/// The mock list with the given states applied in order; extra peers stay idle.
private func previewPeers(_ states: NearbyPeerState...) -> [NearbyPeer] {
  NearbyPeer.mockList.enumerated().map { index, peer in
    var peer = peer
    if index < states.count { peer.state = states[index] }
    return peer
  }
}

#Preview("Permission Required") {
  addFriendsPreview(.unavailable(.permissionRequired))
}

#Preview("Permission Denied") {
  addFriendsPreview(.unavailable(.permissionDenied))
}

#Preview("Bluetooth Off") {
  addFriendsPreview(.unavailable(.bluetoothOff))
}

#Preview("Unsupported Device") {
  addFriendsPreview(.unavailable(.unsupported))
}

#Preview("Searching") {
  addFriendsPreview(.scanning(peers: []))
}

#Preview("People Found") {
  addFriendsPreview(.scanning(peers: Array(previewPeers().prefix(3))))
}

#Preview("Request Sent") {
  addFriendsPreview(.scanning(peers: previewPeers(.requested)))
}

#Preview("Incoming Request") {
  addFriendsPreview(.scanning(peers: previewPeers(.idle, .incoming)))
}

#Preview("Multiple Requests") {
  // Four pending: three cards drawn, "+3" on the front one. Accept or decline
  // to watch the next card come forward.
  addFriendsPreview(.scanning(peers: previewPeers(.incoming, .incoming, .idle, .incoming, .incoming)))
}

#Preview("Adding") {
  addFriendsPreview(.scanning(peers: previewPeers(.adding)))
}

#Preview("Added") {
  addFriendsPreview(.scanning(peers: previewPeers(.added, .added)))
}

#Preview("Failed") {
  addFriendsPreview(.scanning(peers: previewPeers(.failed)))
}

#Preview("Every State") {
  addFriendsPreview(.scanning(peers: previewPeers(.idle, .requested, .incoming, .adding, .added)))
}

#Preview("Code Unavailable") {
  addFriendsPreview(.scanning(peers: []), myCode: nil, isMyCodeUnavailable: true)
}

#Preview("As Sheet") {
  @Previewable @State var showSheet = true

  Button("Show Add Friends") {
    showSheet = true
  }
  .sheet(isPresented: $showSheet) {
    addFriendsPreview(.scanning(peers: previewPeers(.idle, .incoming)))
  }
}
#endif
