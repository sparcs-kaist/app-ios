//
//  PlatformViewCompat.swift
//  BuddyDomain
//
//  A handful of SwiftUI modifiers and toolbar placements are declared
//  `@available(macOS, unavailable)`. Shimming them here keeps ~40 shared call
//  sites free of `#if` noise; each shim maps onto the nearest Mac behaviour, or
//  no-ops where the concept simply doesn't exist.
//
//  This is a compatibility layer, not UI design — whether each screen actually
//  reads well on macOS is a separate pass.
//

#if os(macOS)
import SwiftUI

// MARK: - Toolbar placements

public extension ToolbarItemPlacement {
  /// iOS puts these on the navigation bar; the Mac equivalents are the window
  /// toolbar's leading (navigation) and trailing (primary action) regions.
  static var topBarLeading: ToolbarItemPlacement { .navigation }
  static var topBarTrailing: ToolbarItemPlacement { .primaryAction }

  /// No bottom toolbar on macOS — let the system place these items rather than
  /// dropping them. (`.keyboard` is *not* shimmed: AppKit already declares it, and
  /// redeclaring it here makes every use ambiguous.)
  static var bottomBar: ToolbarItemPlacement { .automatic }
}

// MARK: - Navigation bar title display mode

/// Stands in for `NavigationBarItem.TitleDisplayMode`, which is itself
/// unavailable on macOS. Declaring our own type is what lets `.inline` at the
/// call sites still resolve.
public enum BuddyTitleDisplayMode: Sendable {
  case automatic
  case inline
  case large
}

public extension View {
  /// Mac windows have no large-title navigation bar, so this is a no-op that
  /// exists purely so shared views compile.
  func navigationBarTitleDisplayMode(_ mode: BuddyTitleDisplayMode) -> some View {
    self
  }
}

// MARK: - Keyboard type

/// Stands in for `UIKeyboardType`. macOS has no software keyboard to configure, so
/// the modifier below is a no-op — the hint simply doesn't apply.
public enum BuddyKeyboardType: Sendable {
  case `default`
  case numberPad
  case decimalPad
  case phonePad
  case emailAddress
  case url
}

public extension View {
  func keyboardType(_ type: BuddyKeyboardType) -> some View {
    self
  }
}

// MARK: - Full screen covers

public extension View {
  /// macOS has no full-screen presentation style; a sheet is the closest
  /// equivalent and is what these screens should be on a Mac anyway.
  func fullScreenCover<Content: View>(
    isPresented: Binding<Bool>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
  }

  func fullScreenCover<Item: Identifiable, Content: View>(
    item: Binding<Item?>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
  ) -> some View {
    sheet(item: item, onDismiss: onDismiss, content: content)
  }
}

// MARK: - Tab bar visibility

/// Stands in for `ToolbarPlacement.tabBar`, which is unavailable on macOS.
///
/// Every call site is `.toolbar(.hidden, for: .tabBar)` — the iOS idiom of hiding
/// the tab bar when pushing a detail view. A Mac sidebar has no tab bar to hide,
/// and mapping this onto `.windowToolbar` or `.automatic` would wrongly hide the
/// real window toolbar, so it needs to be an outright no-op. That means shimming
/// the modifiers rather than the placement value.
public enum BuddyToolbarPlacement: Sendable {
  case tabBar
}

public extension View {
  func toolbar(_ visibility: Visibility, for placement: BuddyToolbarPlacement) -> some View {
    self
  }

  func toolbarVisibility(_ visibility: Visibility, for placement: BuddyToolbarPlacement) -> some View {
    self
  }
}

#endif
