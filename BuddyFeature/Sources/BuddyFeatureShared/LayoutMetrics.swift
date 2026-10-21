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
  /// iPhones in landscape, whose content area is about 750 points wide.
  ///
  /// 700 rather than 600 so the inner display of iPhone Duo in portrait (669
  /// points) keeps one column, where two would each be about 320 points.
  /// iPad mini in portrait, the narrowest iPad, is 744.
  public static let twoColumnWidthThreshold: CGFloat = 700
}
