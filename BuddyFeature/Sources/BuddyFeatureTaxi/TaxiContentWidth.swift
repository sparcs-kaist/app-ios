//
//  TaxiContentWidth.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2026.
//

import SwiftUI

/// Shared layout metrics for the taxi screens so they read as a single,
/// comfortable column instead of stretching edge-to-edge in landscape or on iPad.
enum TaxiLayout {
  /// Maximum width of the taxi content column. On narrow screens (iPhone
  /// portrait) the content still fills the available width; on wider screens
  /// (landscape, iPad, split view) it caps here and centres.
  static let maxContentWidth: CGFloat = 600
}

extension View {
  /// Constrains content to `TaxiLayout.maxContentWidth` and centres it within
  /// the available space. The inner frame caps the width while the outer frame
  /// expands to full width so the capped column sits in the middle.
  func taxiContentWidth() -> some View {
    self
      .frame(maxWidth: TaxiLayout.maxContentWidth)
      .frame(maxWidth: .infinity)
  }
}
