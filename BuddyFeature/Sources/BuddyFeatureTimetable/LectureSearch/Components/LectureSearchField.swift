//
//  LectureSearchField.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import SwiftUI

/// The keyword field of the lecture search bar.
///
/// Drawn here rather than with `searchable` so it shares its edges with the filter chips above
/// it; the system search field insets itself differently at rest and while typing.
struct LectureSearchField: View {
  @Binding var text: String
  var isFocused: FocusState<Bool>.Binding

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      TextField(String(localized: "Search", bundle: .module), text: $text)
        .focused(isFocused)
        .submitLabel(.search)
        .onSubmit {
          isFocused.wrappedValue = false
        }

      if !text.isEmpty {
        Button(String(localized: "Clear", bundle: .module), systemImage: "xmark.circle.fill") {
          text = ""
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .glassEffect(.regular.interactive(), in: .capsule)
    .contentShape(.capsule)
    .onTapGesture {
      isFocused.wrappedValue = true
    }
    .accessibilityAddTraits(.isSearchField)
  }
}
