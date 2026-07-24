//
//  CGFloat+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 24/06/2025.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)

public extension CGFloat {
  @MainActor
  static var screenWidth: CGFloat {
    UIScreen.main.bounds.width
  }
}

#elseif os(macOS)

public extension CGFloat {
  @MainActor
  static var screenWidth: CGFloat {
    // Callers only reach for this when a measured parent width is unavailable,
    // so falling back to a constant on a headless Mac is acceptable.
    NSScreen.main?.frame.width ?? 1440
  }
}

#endif
