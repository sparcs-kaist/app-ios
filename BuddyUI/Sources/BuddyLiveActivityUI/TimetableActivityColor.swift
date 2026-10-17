//
//  TimetableActivityColor.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

import SwiftUI
import BuddyDomain

/// A class colour resolved from the theme, the same one the timetable uses for that lecture.
public struct TimetableActivityColor: Hashable, Sendable {
  public let fill: Color
  public let onBlack: Color
  /// Text drawn on `fill`: the theme's cell text colour, so badges read like timetable cells.
  public let text: Color

  init(fill: Color, onBlack: Color, text: Color = .white) {
    self.fill = fill
    self.onBlack = onBlack
    self.text = text
  }

  public init(colorID: Int, theme: TimetableTheme) {
    let hexColors = theme.hexColors
    text = theme.textColor
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

  /// The theme colour as it is, so the activity matches the timetable. Only a near-black theme
  /// colour, which would vanish on the black background, is lifted just enough to see.
  private static func lifted(_ rgb: (red: Double, green: Double, blue: Double)) -> Color {
    let luma = 0.299 * rgb.red + 0.587 * rgb.green + 0.114 * rgb.blue
    let floor = 0.22
    guard luma < floor else { return Color(red: rgb.red, green: rgb.green, blue: rgb.blue) }
    let mix = (floor - luma) / (1 - luma)
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
