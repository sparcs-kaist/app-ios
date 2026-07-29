//
//  MacOSButtonChrome.swift
//  BuddyFeature
//

import SwiftUI

/// AppKit gives every `Button` the bordered push-button look by default, which paints
/// an opaque grey capsule behind controls that iOS draws flat. Inside the glass
/// containers used for votes, comments, bookmarks and shares that reads as a second,
/// differently tinted pill nested in the first one.
///
/// These two helpers strip that chrome on macOS and leave iOS/iPadOS untouched. They
/// come as a pair on purpose: without a button background AppKit has nothing to
/// hit-test, so `.buttonStyle(.plain)` alone stops the control responding to clicks.
public extension View {
  /// Removes AppKit's bordered background from every `Button` in the subtree.
  /// Pair with `macOSPlainHitArea()` on each button's label.
  @ViewBuilder
  func macOSPlainButtons() -> some View {
    #if os(macOS)
    buttonStyle(.plain)
    #else
    self
    #endif
  }

  /// Restores a clickable rectangle for a button label that no longer has a
  /// background of its own.
  @ViewBuilder
  func macOSPlainHitArea() -> some View {
    #if os(macOS)
    contentShape(.rect)
    #else
    self
    #endif
  }
}
