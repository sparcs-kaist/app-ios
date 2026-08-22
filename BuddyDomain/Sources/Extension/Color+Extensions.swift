//
//  Color+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

public extension Color {
  #if os(iOS)
  // MARK: - Text Colors
  static let lightText = Color(UIColor.lightText)
  static let darkText = Color(UIColor.darkText)
  static let placeholderText = Color(UIColor.placeholderText)

  // MARK: - Label Colors
  static let label = Color(UIColor.label)
  static let secondaryLabel = Color(UIColor.secondaryLabel)
  static let tertiaryLabel = Color(UIColor.tertiaryLabel)
  static let quaternaryLabel = Color(UIColor.quaternaryLabel)

  // MARK: - Background Colors
  static let systemBackground = Color(UIColor.systemBackground)
  static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
  static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)

  // MARK: - Fill Colors
  static let systemFill = Color(UIColor.systemFill)
  static let secondarySystemFill = Color(UIColor.secondarySystemFill)
  static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
  static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)

  // MARK: - Grouped Background Colors
  static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
  static let secondarySystemGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
  static let tertiarySystemGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)

  // MARK: - Gray Colors
  static let systemGray = Color(UIColor.systemGray)
  static let systemGray2 = Color(UIColor.systemGray2)
  static let systemGray3 = Color(UIColor.systemGray3)
  static let systemGray4 = Color(UIColor.systemGray4)
  static let systemGray5 = Color(UIColor.systemGray5)
  static let systemGray6 = Color(UIColor.systemGray6)

  // MARK: - Other Colors
  static let separator = Color(UIColor.separator)
  static let opaqueSeparator = Color(UIColor.opaqueSeparator)
  static let link = Color(UIColor.link)

  // MARK: System Colors
  static let systemBlue = Color(UIColor.systemBlue)
  static let systemPurple = Color(UIColor.systemPurple)
  static let systemGreen = Color(UIColor.systemGreen)
  static let systemYellow = Color(UIColor.systemYellow)
  static let systemOrange = Color(UIColor.systemOrange)
  static let systemPink = Color(UIColor.systemPink)
  static let systemRed = Color(UIColor.systemRed)
  static let systemTeal = Color(UIColor.systemTeal)
  static let systemIndigo = Color(UIColor.systemIndigo)
  #elseif os(macOS)
  // AppKit has no one-to-one match for most of iOS's semantic palette, so these
  // map onto the closest system colour and keep the call sites unchanged.

  // MARK: - Text Colors
  static let lightText = Color.white.opacity(0.6)
  static let darkText = Color.black.opacity(0.85)
  static let placeholderText = Color(NSColor.placeholderTextColor)

  // MARK: - Label Colors
  static let label = Color(NSColor.labelColor)
  static let secondaryLabel = Color(NSColor.secondaryLabelColor)
  static let tertiaryLabel = Color(NSColor.tertiaryLabelColor)
  static let quaternaryLabel = Color(NSColor.quaternaryLabelColor)

  // MARK: - Background Colors
  static let systemBackground = Color(NSColor.textBackgroundColor)
  static let secondarySystemBackground = Color(NSColor.controlBackgroundColor)
  static let tertiarySystemBackground = Color(NSColor.underPageBackgroundColor)

  // MARK: - Fill Colors
  static let systemFill = Color.gray.opacity(0.20)
  static let secondarySystemFill = Color.gray.opacity(0.16)
  static let tertiarySystemFill = Color.gray.opacity(0.12)
  static let quaternarySystemFill = Color.gray.opacity(0.08)

  // MARK: - Grouped Background Colors
  static let systemGroupedBackground = Color(NSColor.windowBackgroundColor)
  static let secondarySystemGroupedBackground = Color(NSColor.controlBackgroundColor)
  static let tertiarySystemGroupedBackground = Color(NSColor.textBackgroundColor)

  // MARK: - Gray Colors
  // AppKit only ships `systemGray`; the numbered steps are approximated by opacity.
  static let systemGray = Color(NSColor.systemGray)
  static let systemGray2 = Color(NSColor.systemGray).opacity(0.85)
  static let systemGray3 = Color(NSColor.systemGray).opacity(0.70)
  static let systemGray4 = Color(NSColor.systemGray).opacity(0.55)
  static let systemGray5 = Color(NSColor.systemGray).opacity(0.40)
  static let systemGray6 = Color(NSColor.systemGray).opacity(0.25)

  // MARK: - Other Colors
  static let separator = Color(NSColor.separatorColor)
  static let opaqueSeparator = Color(NSColor.separatorColor)
  static let link = Color(NSColor.linkColor)

  // MARK: System Colors
  static let systemBlue = Color(NSColor.systemBlue)
  static let systemPurple = Color(NSColor.systemPurple)
  static let systemGreen = Color(NSColor.systemGreen)
  static let systemYellow = Color(NSColor.systemYellow)
  static let systemOrange = Color(NSColor.systemOrange)
  static let systemPink = Color(NSColor.systemPink)
  static let systemRed = Color(NSColor.systemRed)
  static let systemTeal = Color(NSColor.systemTeal)
  static let systemIndigo = Color(NSColor.systemIndigo)
  #endif

  // MARK: - Custom Colors
  static let upvote = Color(hex: "ff4500")
  static let downvote = Color(hex: "047dff")
}

public extension Color {
  /// HSB tweak for dark mode: slightly more saturated, ~20% dimmer.
  func darkTransformedHSB() -> Color {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

    #if canImport(UIKit)
    let ui = UIColor(self)
    guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
    #elseif canImport(AppKit)
    // NSColor.getHue(_:saturation:brightness:alpha:) raises unless the receiver is
    // already in an RGB colour space, so convert first and bail out if that fails.
    guard let ns = NSColor(self).usingColorSpace(.sRGB) else { return self }
    ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    #endif

    // Keep 90% of the original brightness
    let newB = max(min(b * 0.9, 1), 0)
    let newS = max(min(s * 1.05, 1), 0)  // small saturation bump
    return Color(PlatformColor(hue: h, saturation: newS, brightness: newB, alpha: a))
  }
}
