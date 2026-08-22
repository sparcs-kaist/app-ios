//
//  SheetToolbarPlacement.swift
//  BuddyDomain
//

import SwiftUI

public extension ToolbarItemPlacement {
  /// Placement for a sheet's own dismiss button.
  ///
  /// `topBarLeading` shims to `.navigation` on macOS (see `PlatformViewCompat`), which
  /// addresses the *window's* toolbar. A sheet has no window toolbar, so AppKit
  /// silently drops the item — and combined with `interactiveDismissDisabled()` that
  /// left every sheet in the app with no way out on macOS: no close button and no
  /// Escape either. `.cancellationAction` renders inside the sheet itself and picks up
  /// Escape as the dialog's cancel button.
  ///
  /// On iOS this is exactly `topBarLeading`, so nothing moves there.
  static var sheetCancellation: ToolbarItemPlacement {
    #if os(macOS)
    .cancellationAction
    #else
    .topBarLeading
    #endif
  }

  /// The confirming counterpart to ``sheetCancellation``. Same reasoning:
  /// `.primaryAction` is a window-toolbar region, `.confirmationAction` is a sheet one.
  static var sheetConfirmation: ToolbarItemPlacement {
    #if os(macOS)
    .confirmationAction
    #else
    .topBarTrailing
    #endif
  }
}
