//
//  TimetableThemeBrief.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 16/09/2026.
//

import Foundation

/// What the on-device model is asked for when someone describes a theme in
/// words: a name, whether the timetable should read light or dark, and a
/// handful of anchor colours.
///
/// Everything a ``TimetableTheme`` actually needs — sixteen cell colours, the
/// text on them, the background, the separators and the grid labels — is
/// derived from those anchors rather than generated. A small language model
/// picks a few colours that match a description far better than it balances
/// twenty of them for legibility, so it is only asked for the part it is good
/// at.
///
/// Snapshots arrive while the model is still writing, which is why every field
/// is optional and `anchorHexColors` grows as it goes. The colours are
/// candidates, not guarantees: `RRGGBB` is asked for but not enforced, so the
/// consumer validates them.
public struct TimetableThemeBrief: Equatable, Sendable {
  public enum Appearance: String, Equatable, Sendable {
    case light
    case dark
  }

  public var name: String?
  public var appearance: Appearance?
  /// The colours the description is made of, most important first. The first
  /// one tints the grid, as a photo's heaviest colour does.
  public var anchorHexColors: [String]

  public init(
    name: String? = nil,
    appearance: Appearance? = nil,
    anchorHexColors: [String] = []
  ) {
    self.name = name
    self.appearance = appearance
    self.anchorHexColors = anchorHexColors
  }
}

/// Why a described theme could not be generated. Each case is worth telling
/// the person apart: only `failed` is worth retrying unchanged.
public enum TimetableThemeGenerationError: Error, Equatable, Sendable {
  /// The device doesn't support Apple Intelligence, it is switched off, or the
  /// model is still downloading.
  case unavailable
  /// The description tripped the model's safety guardrails.
  case unsafeRequest
  /// The model finished without naming a single usable colour.
  case incomplete
  case failed
}
