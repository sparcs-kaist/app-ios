//
//  TopicFilterBar.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import BuddyDomain

/// A board's topics as a row of chips, "All" first, narrowing the list to one of them.
struct TopicFilterBar: View {
  let topics: [AraBoardTopic]
  @Binding var selection: AraBoardTopic?
  /// Whether the posts below are a capped column, which the chips then start in line with. The
  /// Market grid uses the whole width, and its chips start at the edge as its photos do.
  var isAboveColumn = true

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        chip(String(localized: "All", bundle: .module), isSelected: selection == nil) {
          selection = nil
        }
        ForEach(topics) { topic in
          chip(topic.name.localized(), isSelected: selection == topic) {
            selection = topic
          }
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 6)
    }
    .scrollIndicators(.hidden)
    // The chips start where the posts below do, and still scroll out to the screen's edges.
    .scrollContentWidth(isEnabled: isAboveColumn)
    .sensoryFeedback(.selection, trigger: selection)
  }

  private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline.weight(isSelected ? .semibold : .regular))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
    .buttonStyle(.plain)
    .foregroundStyle(isSelected ? Color.white : .primary)
    .background {
      if isSelected {
        Capsule().fill(Color.accentColor)
      }
    }
    .glassEffect(isSelected ? .identity : .regular.interactive(), in: .capsule)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .animation(.snappy, value: isSelected)
  }
}
