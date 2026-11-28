//
//  InitialsCircle.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI

/// There are no avatars, so each person gets their initials over a gradient
/// picked from their name. The pick is stable across launches, so the same
/// person keeps the same colours.
struct InitialsCircle: View {
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

  /// Sixteen pairs, so friends share a colour less often: with four friends there's
  /// about a one in three chance two match, against nearly three in four with six.
  private static let palettes: [[Color]] = [
    [Color(red: 0.93, green: 0.33, blue: 0.56), Color(red: 0.55, green: 0.27, blue: 0.93)], // pink → purple
    [Color(red: 0.26, green: 0.52, blue: 0.96), Color(red: 0.36, green: 0.85, blue: 0.93)], // blue → cyan
    [Color(red: 0.98, green: 0.60, blue: 0.26), Color(red: 0.93, green: 0.30, blue: 0.40)], // orange → red
    [Color(red: 0.30, green: 0.80, blue: 0.56), Color(red: 0.20, green: 0.55, blue: 0.85)], // green → blue
    [Color(red: 0.62, green: 0.40, blue: 0.98), Color(red: 0.30, green: 0.35, blue: 0.90)], // violet → indigo
    [Color(red: 0.96, green: 0.45, blue: 0.75), Color(red: 0.99, green: 0.72, blue: 0.40)], // pink → peach
    [Color(red: 0.18, green: 0.75, blue: 0.75), Color(red: 0.20, green: 0.62, blue: 0.45)], // teal → emerald
    [Color(red: 0.99, green: 0.80, blue: 0.30), Color(red: 0.97, green: 0.52, blue: 0.22)], // sunflower → orange
    [Color(red: 0.40, green: 0.75, blue: 0.98), Color(red: 0.35, green: 0.40, blue: 0.92)], // sky → indigo
    [Color(red: 0.99, green: 0.50, blue: 0.45), Color(red: 0.85, green: 0.25, blue: 0.65)], // coral → magenta
    [Color(red: 0.62, green: 0.85, blue: 0.35), Color(red: 0.18, green: 0.68, blue: 0.62)], // lime → teal
    [Color(red: 0.72, green: 0.60, blue: 0.98), Color(red: 0.95, green: 0.50, blue: 0.70)], // lavender → pink
    [Color(red: 0.88, green: 0.22, blue: 0.35), Color(red: 0.98, green: 0.55, blue: 0.30)], // crimson → orange
    [Color(red: 0.15, green: 0.60, blue: 0.80), Color(red: 0.18, green: 0.30, blue: 0.65)], // ocean → navy
    [Color(red: 0.40, green: 0.88, blue: 0.70), Color(red: 0.35, green: 0.65, blue: 0.95)], // mint → sky
    [Color(red: 0.55, green: 0.25, blue: 0.60), Color(red: 0.92, green: 0.42, blue: 0.55)]  // plum → rose
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
    InitialsCircle(name: "김수진")
    InitialsCircle(name: "Minho Lee")
    InitialsCircle(name: "Haeun")
  }
  .padding()
  .background(.black)
}
