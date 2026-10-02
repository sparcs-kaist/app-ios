//
//  InspectorChrome.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI

/// How a screen in the full-screen search's inspector goes back or closes.
///
/// The inspector has no navigation stack of its own: inside the inspector of a pushed screen, one
/// would pop that screen. Without one, toolbar items and titles in the inspector join the search's
/// navigation bar, so its screens draw their own header instead.
struct InspectorNavigation {
  let canGoBack: Bool
  let goBack: @MainActor () -> Void
  let close: @MainActor () -> Void
}

extension EnvironmentValues {
  /// Set on screens shown in the full-screen search's inspector; `nil` anywhere else.
  @Entry var inspectorNavigation: InspectorNavigation? = nil
}

extension View {
  /// Titles a screen: in the navigation bar, or in the inspector, in a header with `actions`, which
  /// the screen otherwise puts in its toolbar.
  func screenTitle<Actions: View>(_ title: String, @ViewBuilder actions: () -> Actions) -> some View {
    modifier(ScreenTitleModifier(title: title, actions: actions()))
  }
}

private struct ScreenTitleModifier<Actions: View>: ViewModifier {
  let title: String
  let actions: Actions
  @Environment(\.inspectorNavigation) private var inspectorNavigation

  func body(content: Content) -> some View {
    // A screen is shown either in the inspector or not for as long as it exists, so the branches
    // never swap under it.
    if let inspectorNavigation {
      content
        .safeAreaBar(edge: .top) {
          InspectorHeader(title: title, navigation: inspectorNavigation, actions: actions)
        }
    } else {
      content
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct InspectorHeader<Actions: View>: View {
  let title: String
  let navigation: InspectorNavigation
  let actions: Actions

  var body: some View {
    HStack(spacing: 12) {
      Group {
        if navigation.canGoBack {
          Button(String(localized: "Back", bundle: .module), systemImage: "chevron.backward") {
            navigation.goBack()
          }
        } else {
          Button(String(localized: "Close", bundle: .module), systemImage: "xmark") {
            navigation.close()
          }
        }
      }
      .labelStyle(.iconOnly)
      .buttonBorderShape(.circle)
      .buttonStyle(.glass)
      .controlSize(.large)

      Text(title)
        .font(.headline)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)

      HStack(spacing: 8) {
        actions
      }
      .labelStyle(.iconOnly)
      .buttonBorderShape(.circle)
      .controlSize(.large)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}
