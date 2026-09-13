//
//  LayoutMetrics.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/09/2026.
//

import Foundation

/// Shared layout constants used across feature modules.
public enum LayoutMetrics {
  /// Width past which views switch to a two-column layout. Driven by the
  /// actual available width (not the size class) so it also kicks in for
  /// iPhones in landscape, which report a compact horizontal size class.
  public static let twoColumnWidthThreshold: CGFloat = 600
}
