//
//  Color+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI

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

    /// Six-digit RRGGBB, the storage format used by timetable themes.
    var hexString: String {
      #if os(iOS) || os(watchOS) || os(tvOS)
      var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
      UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
      return String(
        format: "%02X%02X%02X",
        Int((max(0, min(1, red)) * 255).rounded()),
        Int((max(0, min(1, green)) * 255).rounded()),
        Int((max(0, min(1, blue)) * 255).rounded())
      )
      #else
      return "000000"
      #endif
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
  #endif

  // MARK: - Custom Colors
  static let upvote = Color(hex: "ff4500")
  static let downvote = Color(hex: "047dff")
}

public extension Color {
  /// HSB tweak for dark mode: slightly more saturated, ~20% dimmer.
  func darkTransformedHSB() -> Color {
    let ui = UIColor(self)
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      // Keep 90% of the original brightness
      let newB = max(min(b * 0.9, 1), 0)
      let newS = max(min(s * 1.05, 1), 0)  // small saturation bump
      return Color(UIColor(hue: h, saturation: newS, brightness: newB, alpha: a))
    }
    return self
  }
}
