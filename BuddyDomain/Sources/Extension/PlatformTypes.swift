//
//  PlatformTypes.swift
//  BuddyDomain
//
//  Bridges the UIKit types that leak into the domain layer onto their AppKit
//  counterparts so the same sources build for iOS, watchOS and native macOS.
//

#if canImport(UIKit)
import UIKit

public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor

#elseif canImport(AppKit)
import AppKit

public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
#endif

import SwiftUI

public extension Image {
  /// SwiftUI spells this `init(uiImage:)` on iOS and `init(nsImage:)` on macOS.
  init(platformImage: PlatformImage) {
    #if canImport(UIKit)
    self.init(uiImage: platformImage)
    #elseif canImport(AppKit)
    self.init(nsImage: platformImage)
    #endif
  }
}
