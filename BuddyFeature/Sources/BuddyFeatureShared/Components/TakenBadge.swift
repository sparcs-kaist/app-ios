//
//  TakenBadge.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 01/10/2026.
//

import SwiftUI

/// A small pill marking a course the user has already taken.
public struct TakenBadge: View {
  @ScaledMetric(relativeTo: .caption) private var inset: CGFloat = 3
  @Environment(\.redactionReasons) private var redactionReasons

  public init() { }

  public var body: some View {
    // Loading placeholders use mock courses, which should not claim to be taken.
    if !redactionReasons.contains(.placeholder) {
      badge
    }
  }

  private var badge: some View {
    // Not a Label: list rows reduce a Label to its icon.
    HStack(spacing: 4) {
      // Sized to the text line and inset as much as the top and bottom, so the circle sits
      // concentric with the capsule's rounded end.
      Image(systemName: "checkmark.circle.fill")
        .imageScale(.large)
      Text("Taken", bundle: .module)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(.tint)
    .padding(.vertical, inset)
    .padding(.leading, inset)
    .padding(.trailing, 8)
    .background(.tint.quaternary, in: .capsule)
    .fixedSize()
    .accessibilityElement(children: .combine)
  }
}


#Preview {
	TakenBadge()
}
