//
//  BuddySizeClass.swift
//  BuddyDomain
//
//  `EnvironmentValues.horizontalSizeClass` is `@available(macOS, unavailable)`, and
//  shadowing it with a same-named extension makes `@Environment(\.horizontalSizeClass)`
//  ambiguous rather than resolving to the shim. So this exposes a distinctly named
//  key instead: views write
//
//      @Environment(\.buddyHorizontalSizeClass) private var horizontalSizeClass
//
//  which keeps the local variable — and therefore every `== .compact` comparison —
//  unchanged.
//

import SwiftUI

/// Mirrors UIKit's `UserInterfaceSizeClass`, minus the platform restriction.
public enum BuddySizeClass: Sendable {
  case compact
  case regular
}

public extension EnvironmentValues {
  var buddyHorizontalSizeClass: BuddySizeClass? {
    #if os(iOS)
    switch horizontalSizeClass {
    case .compact: .compact
    case .regular: .regular
    default: nil
    }
    #elseif os(macOS)
    // A Mac window is always wide, so shared views take the same branch as iPad.
    .regular
    #else
    nil
    #endif
  }
}
