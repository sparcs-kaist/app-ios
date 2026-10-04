//
//  MyFriendCodeView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI

/// The user's own code on one line, sitting above the "Add Friends via Code"
/// button. Tapping it copies the code, like the theme share code in
/// `TimetableThemeSharingView`.
struct MyFriendCodeView: View {
  let code: String?
  let isUnavailable: Bool

  @State private var didCopyCode = false

  var body: some View {
    HStack(spacing: 8) {
      Text("Your Code", bundle: .module)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Group {
        if let code {
          Button {
            UIPasteboard.general.string = code
            didCopyCode = true
          } label: {
            HStack(spacing: 6) {
              Text(code)
                .font(.title3)
                .fontDesign(.monospaced)

              Image(systemName: didCopyCode ? "checkmark" : "document.on.document")
                .font(.subheadline)
                .contentTransition(.symbolEffect(.replace))
            }
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
        } else if isUnavailable {
          Text("Unavailable", bundle: .module)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } else {
          ProgressView()
            .controlSize(.small)
        }
      }
      .transition(.blurReplace)
    }
    .frame(maxWidth: .infinity)
    .animation(.smooth, value: code)
    .animation(.smooth, value: isUnavailable)
  }
}
