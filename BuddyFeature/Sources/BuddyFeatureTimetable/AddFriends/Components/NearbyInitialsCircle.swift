//
//  NearbyInitialsCircle.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI

/// There are no avatars, so each person gets their initials over a gradient
/// picked from their name. The pick is stable across launches, so the same
/// person keeps the same colours.
struct NearbyInitialsCircle: View {
  let name: String
  var diameter: CGFloat = 72

  var body: some View {
    Text(Self.initials(for: name))
      .font(.system(size: diameter * 0.36, weight: .semibold, design: .rounded))
      .foregroundStyle(.white)
      .minimumScaleFactor(0.6)
      .frame(width: diameter, height: diameter)
      .background {
        Circle()
          .fill(Self.gradient(for: name))
          .opacity(0.7)
      }
      .accessibilityHidden(true)
  }

  // MARK: - Helpers

  /// "김수진" → "수진" (given name, as Korean speakers usually address friends),
  /// "Minho Lee" → "ML", "Haeun" → "H".
  static func initials(for name: String) -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let words = trimmed.split(whereSeparator: \.isWhitespace)

    if words.count >= 2 {
      return words.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
    if trimmed.unicodeScalars.contains(where: { (0xAC00...0xD7A3).contains($0.value) }), trimmed.count >= 3 {
      return String(trimmed.dropFirst())
    }
    return trimmed.first.map { String($0).uppercased() } ?? "?"
  }

  private static let palettes: [[Color]] = [
    [Color(red: 0.93, green: 0.33, blue: 0.56), Color(red: 0.55, green: 0.27, blue: 0.93)],
    [Color(red: 0.26, green: 0.52, blue: 0.96), Color(red: 0.36, green: 0.85, blue: 0.93)],
    [Color(red: 0.98, green: 0.60, blue: 0.26), Color(red: 0.93, green: 0.30, blue: 0.40)],
    [Color(red: 0.30, green: 0.80, blue: 0.56), Color(red: 0.20, green: 0.55, blue: 0.85)],
    [Color(red: 0.62, green: 0.40, blue: 0.98), Color(red: 0.30, green: 0.35, blue: 0.90)],
    [Color(red: 0.96, green: 0.45, blue: 0.75), Color(red: 0.99, green: 0.72, blue: 0.40)]
  ]

  /// `hashValue` is seeded per launch, so sum the scalars instead.
  private static func gradient(for name: String) -> LinearGradient {
    let seed = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
    let colors = palettes[seed % palettes.count]
    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

#Preview {
  HStack {
    NearbyInitialsCircle(name: "김수진")
    NearbyInitialsCircle(name: "Minho Lee")
    NearbyInitialsCircle(name: "Haeun")
  }
  .padding()
  .background(.black)
}
