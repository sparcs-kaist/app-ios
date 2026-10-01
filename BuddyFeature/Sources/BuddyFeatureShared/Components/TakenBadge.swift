//
//  TakenBadge.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 01/10/2026.
//

import SwiftUI

/// A small pill marking a course the user has already taken.
public struct TakenBadge: View {
  public init() { }

  public var body: some View {
    // Not a Label: list rows reduce a Label to its icon.
    HStack(spacing: 3) {
      Image(systemName: "checkmark.circle.fill")
      Text("Taken", bundle: .module)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(.tint)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(.tint.quaternary, in: .capsule)
    .fixedSize()
    .accessibilityElement(children: .combine)
  }
}
