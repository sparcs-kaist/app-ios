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

  @Environment(\.dismiss) private var dismiss

  @State private var isCodePromptPresented = false
  @State private var codeInput = ""
  @State private var didCopyCode = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        HStack {
          Text("Nearby Friends", bundle: .module)
            .font(.headline)
            .foregroundStyle(.primary.opacity(0.8))

          Spacer()
        }

        Text("Scanning for nearby friends...", bundle: .module)
          .foregroundStyle(.secondary)
          .padding()

        Spacer()

        // Centred in the remaining space so it never collides with the pinned
        // bottom bar.
        myCodeCard

        Spacer()
      }
      .padding()
      .navigationTitle(Text("Add Friends", bundle: .module))
    }
    .safeAreaBar(edge: .bottom) {
      Button {
        codeInput = ""
        isCodePromptPresented = true
      } label: {
        Text("Add Friends via Code", bundle: .module)
      }
      .buttonSizing(.flexible)
      .controlSize(.large)
      .scenePadding()
      .buttonStyle(.glass)
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
    .background {
      AnimatedMeshGradientView()
        .ignoresSafeArea()
    }
    // Scoped to this subtree; `.preferredColorScheme` would propagate to the
    // presenting window and briefly flash the parent dark while presenting.
    .environment(\.colorScheme, .dark)
  }

  // MARK: - My Code

  @ViewBuilder
  private var myCodeCard: some View {
    // Mirrors the theme share code in `TimetableThemeSharingView`, minus the
    // rounded background so it sits directly on the gradient.
    VStack {
      if let code = viewModel.myCode {
        Button {
          UIPasteboard.general.string = code
          didCopyCode = true
        } label: {
          HStack {
            Text(code)
              .font(.largeTitle)
              .fontDesign(.monospaced)

            Image(systemName: didCopyCode ? "checkmark" : "document.on.document")
              .contentTransition(.symbolEffect(.replace))
          }
          .padding()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(code))
        .accessibilityHint(Text("Copies the code", bundle: .module))
        // The checkmark is only confirmation, so it reverts to the copy symbol.
        .task(id: didCopyCode) {
          guard didCopyCode else { return }
          try? await Task.sleep(for: .seconds(2))
          didCopyCode = false
        }

        Text("Share this code with a friend so they can add you.", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding()
      } else if viewModel.isMyCodeUnavailable {
        Text("Your code isn’t available right now.", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding()
      } else {
        ProgressView()
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .transition(.blurReplace)
    .animation(.smooth, value: viewModel.myCode)
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

#Preview {
  @Previewable @State var showSheet = true

  NavigationStack {
    Button("hello") {
      showSheet = true
    }
    .sheet(isPresented: $showSheet) {
      AddFriendsView(viewModel: FriendsListViewModel())
    }
  }
}
