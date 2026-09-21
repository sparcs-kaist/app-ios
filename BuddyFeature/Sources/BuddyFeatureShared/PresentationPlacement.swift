//
//  PresentationPlacement.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 21/09/2026.
//

import SwiftUI

/// Edge placement for sheets on displays wide enough for the system to honour
/// it; elsewhere the sheet keeps its usual placement.
///
/// These wrap `presentationPlacement(_:)`, which is iOS 27.0 while the packages
/// deploy to 26, so the availability check lives here rather than at every call
/// site. Placement also decides a sheet's bar axis on iPhone Duo's inner
/// display: a *trailing* sheet gets a vertical bar, while centred and leading
/// sheets keep horizontal bars.
public extension View {
  /// Anchors a sheet to the trailing edge.
  @ViewBuilder
  func trailingPresentationPlacement() -> some View {
    if #available(iOS 27.0, *) {
      presentationPlacement(.trailing)
    } else {
      self
    }
  }

  /// Anchors a sheet to the leading edge.
  @ViewBuilder
  func leadingPresentationPlacement() -> some View {
    if #available(iOS 27.0, *) {
      presentationPlacement(.leading)
    } else {
      self
    }
  }
}
