//
//  FeedContentWidth.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2026.
//

import SwiftUI

/// Shared layout metrics for the feed so it reads as a single, comfortable
/// column instead of stretching edge-to-edge in landscape or on iPad.
enum FeedLayout {
  /// Maximum width of the feed content column. On narrow screens (iPhone
  /// portrait) the content still fills the available width; on wider screens
  /// (landscape, iPad, split view) it caps here and centres.
  static let maxContentWidth: CGFloat = 600
}

extension View {
  /// Constrains content to `FeedLayout.maxContentWidth` and centres it within
  /// the available space. The inner frame caps the width while the outer frame
  /// expands to full width so the capped column sits in the middle.
  func feedContentWidth() -> some View {
    self
      .frame(maxWidth: FeedLayout.maxContentWidth)
      .frame(maxWidth: .infinity)
  }
}
