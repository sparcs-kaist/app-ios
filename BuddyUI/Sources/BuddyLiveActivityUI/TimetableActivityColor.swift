//
//  TimetableActivityColor.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

import SwiftUI
import BuddyDomain

/// A class colour resolved from the theme, plus a variant that stays readable on the
/// Dynamic Island's black background (dark theme colours such as navy disappear there).
public struct TimetableActivityColor: Hashable, Sendable {
  public let fill: Color
  public let onBlack: Color

  init(fill: Color, onBlack: Color) {
    self.fill = fill
    self.onBlack = onBlack
  }

  public init(colorID: Int, theme: TimetableTheme) {
    let hexColors = theme.hexColors
    guard !hexColors.isEmpty else {
      fill = .accentColor
      onBlack = .accentColor
      return
    }
    let hex = hexColors[((colorID % hexColors.count) + hexColors.count) % hexColors.count]
    let rgb = Self.rgb(hex: hex)
    fill = Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    onBlack = Self.lifted(rgb)
  }

  /// Mixes towards white until the colour reaches a readable brightness on black.
  private static func lifted(_ rgb: (red: Double, green: Double, blue: Double)) -> Color {
    let luma = 0.299 * rgb.red + 0.587 * rgb.green + 0.114 * rgb.blue
    let target = 0.6
    guard luma < target else { return Color(red: rgb.red, green: rgb.green, blue: rgb.blue) }
    let mix = (target - luma) / (1 - luma)
    return Color(
      red: rgb.red + (1 - rgb.red) * mix,
      green: rgb.green + (1 - rgb.green) * mix,
      blue: rgb.blue + (1 - rgb.blue) * mix
    )
  }

  private static func rgb(hex: String) -> (red: Double, green: Double, blue: Double) {
    var value: UInt64 = 0
    Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&value)
    return (
      Double((value >> 16) & 0xFF) / 255,
      Double((value >> 8) & 0xFF) / 255,
      Double(value & 0xFF) / 255
    )
  }
}
