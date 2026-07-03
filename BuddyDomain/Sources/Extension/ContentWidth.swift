//
//  ContentWidth.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/07/2026.
//

import SwiftUI

/// Shared layout metrics so scrollable content reads as a single, comfortable
/// column instead of stretching edge-to-edge in landscape or on iPad.
public enum ContentLayout {
  /// Maximum width of a content column. On narrow screens (iPhone portrait) the
  /// content still fills the available width; on wider screens (landscape, iPad,
  /// split view) it caps here and centres.
  public static let maxContentWidth: CGFloat = 600
}

public extension View {
  /// Constrains content to `ContentLayout.maxContentWidth` and centres it within
  /// the available space. The inner frame caps the width while the outer frame
  /// expands to full width so the capped column sits in the middle.
  func contentWidth() -> some View {
    self
      .frame(maxWidth: ContentLayout.maxContentWidth)
      .frame(maxWidth: .infinity)
  }
}
