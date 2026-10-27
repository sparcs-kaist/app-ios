//
//  TaxiRideTitle.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain

/// The chat's title, Messages-style: the room's name and route in a capsule, under the riders'
/// photos in the navigation bar. Tapping it opens the ride's info.
///
/// It sits just below the bar rather than in it: the photos and the capsule together are taller
/// than the bar, and whatever hangs outside the bar is drawn but cannot be tapped.
struct TaxiRideTitle: View {
  let title: String
  let room: TaxiRoom
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        VStack(spacing: 0) {
          Text(title)
            .font(.caption.weight(.semibold))
          Text("\(room.source.title.localized()) → \(room.destination.title.localized())", bundle: .module)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .lineLimit(1)

        Image(systemName: "chevron.right")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 4)
      .foregroundStyle(.primary)
      .contentShape(.capsule)
    }
    .buttonStyle(.plain)
    .glassEffect(.regular.interactive(), in: .capsule)
    .accessibilityElement(children: .combine)
    .accessibilityHint(Text("Shows the ride's details", bundle: .module))
  }
}
