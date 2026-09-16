//
//  TimetableDescribedPalette.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import Foundation
import BuddyDomain

/// Turns the handful of colours the model names into a full theme by handing
/// them to the same code a photo's colours go through.
///
/// This is the whole of it, and that is the point. Asking the model for all
/// sixteen block colours, a grid colour and a text colour put the hardest part
/// of the job — sixteen colours that are distinct, legible and look like one
/// set — on the thing least able to do it, and needed a second pile of code to
/// repair the answer afterwards. Naming three to six colours is something it
/// is reliably good at. Turning a few colours into a themed grid is something
/// ``TimetablePhotoPalette`` has done well since it shipped, so a description
/// now takes exactly that route: the model's colours stand in for a photo's
/// clusters, and everything downstream is shared.
extension TimetablePalette {
  /// Returns `nil` while there is not yet enough of a brief to draw, which is
  /// the state most snapshots arrive in.
  static func derived(from brief: TimetableThemeBrief, cellCount: Int) -> TimetablePalette? {
    guard let appearance = brief.appearance else { return nil }
    let seeds = seeds(fromHexColors: brief.anchorHexColors)
    guard let dominant = seeds.first else { return nil }

    return derived(
      seeds: seeds,
      dominant: dominant,
      isDark: appearance == .dark,
      cellCount: cellCount
    )
  }

  /// Seeds from the colours the model named, in the order it named them —
  /// first is the one the grid takes its tint from, exactly as a photo's
  /// heaviest cluster is.
  ///
  /// The model is asked for `RRGGBB` but not held to it, and snapshots arrive
  /// with the colour currently being written only half there, so anything that
  /// isn't a complete hex colour is dropped rather than guessed at. Colours
  /// too close together are then folded the same way a photo's clusters are.
  static func seeds(fromHexColors hexColors: [String]) -> [Oklab] {
    distinctSeeds(from: hexColors.compactMap(rgb(fromHex:)).map(\.oklab))
  }

  /// Accepts `RRGGBB` and the three-digit `RGB` shorthand, either case, with
  /// or without a leading `#`.
  private static func rgb(fromHex hex: String) -> RGB? {
    let digits = hex
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .uppercased()
      .drop { $0 == "#" }
    guard digits.allSatisfy(\.isHexDigit) else { return nil }

    let expanded: String
    switch digits.count {
    case 6: expanded = String(digits)
    case 3: expanded = digits.map { "\($0)\($0)" }.joined()
    default: return nil
    }

    guard let value = UInt32(expanded, radix: 16) else { return nil }
    return RGB(SIMD3(
      Double((value >> 16) & 0xFF),
      Double((value >> 8) & 0xFF),
      Double(value & 0xFF)
    ) / 255)
  }
}
