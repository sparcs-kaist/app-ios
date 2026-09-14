//
//  TimetableTheme.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI

/// A colour set for the timetable: cell backgrounds, cell text, and the class
/// colour dots reused by the lecture list and the Next Class widget.
///
/// Provided themes are read-only; the user's own themes are stored in the shared
/// app group so widgets can render them too. See ``TimetableThemeStore``.
public struct TimetableTheme: Identifiable, Hashable, Codable, Sendable {
  public let id: String
  public var name: String
  public var hexColors: [String]
  public var textColorHex: String
  public let isBuiltIn: Bool

  public init(
    id: String,
    name: String,
    hexColors: [String],
    textColorHex: String,
    isBuiltIn: Bool = false
  ) {
    self.id = id
    self.name = name
    self.hexColors = hexColors
    self.textColorHex = textColorHex
    self.isBuiltIn = isBuiltIn
  }

  public var colors: [Color] { hexColors.map { Color(hex: $0) } }
  public var textColor: Color { Color(hex: textColorHex) }

  /// Provided themes are localised; a user's theme keeps the name they typed.
  public var displayName: String {
    guard isBuiltIn, let localized = Self.localizedBuiltInName(for: id) else { return name }
    return localized
  }

  /// Stable colour for a course, so the same lecture keeps its colour across
  /// launches and devices.
  public func color(forCourseID courseID: Int) -> Color {
    color(at: courseID)
  }

  /// Stable colour for a custom activity block.
  public func color(forActivityID activityID: Int) -> Color {
    color(at: activityID)
  }

  private func color(at index: Int) -> Color {
    let colors = self.colors
    guard !colors.isEmpty else { return .accentColor }
    return colors[((index % colors.count) + colors.count) % colors.count]
  }
}

// MARK: - Provided themes

public extension TimetableTheme {
  /// The colour set used when nothing has been chosen yet.
  static var `default`: TimetableTheme { builtIn[0] }

  static let builtIn: [TimetableTheme] = [
    TimetableTheme(
      id: "builtin.default",
      name: "Default",
      hexColors: [
        "C3BA0A", "E34B6C", "307878", "B4C94B",
        "1D8253", "FA9C3E", "F06E70", "233575",
        "63A763", "9D4EDD", "68C2D9", "DD615D",
        "8F64C5", "F26549", "67929E", "6476C5"
      ],
      textColorHex: "FFFFFF",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.legacy",
      name: "Legacy",
      hexColors: [
        "F2CECE", "F4B3AE", "F2BCA0", "F0D3AB",
        "F1E1A9", "F4F2B3", "DBF4BE", "BEEDD7",
        "B7E2DE", "C9EAF4", "B4D3ED", "B9C5ED",
        "CCC6ED", "D8C1F0", "EBCAEF", "F4BADB"
      ],
      textColorHex: "000000",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.olive",
      name: "Olive",
      hexColors: [
        "0A0B06", "1E2528", "151518", "1E1D19",
        "1E1E1E", "292929", "575760", "6C6C70",
        "C4C3C9", "80978F", "3E3B34", "666652",
        "7B8962", "344620", "70877F", "233A6C"
      ],
      textColorHex: "FFFDE9",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.cherryBlossom",
      name: "Cherry Blossom",
      hexColors: [
        "FFB7C5", "F48FB1", "F06292", "F8BBD0",
        "E1BEE7", "CE93D8", "FFCDD2", "EF9A9A",
        "F6C1CE", "DCEDC8", "AED581", "B2EBF2",
        "80DEEA", "FFF9C4", "FFE082", "D7CCC8"
      ],
      textColorHex: "4A2C35",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.spring",
      name: "Spring",
      hexColors: [
        "A8E6A3", "7FD67A", "C5E1A5", "AED581",
        "DCE775", "FFF176", "FFD54F", "FFAB91",
        "F48FB1", "CE93D8", "B39DDB", "90CAF9",
        "80DEEA", "A5D6A7", "E6EE9C", "FFCC80"
      ],
      textColorHex: "1F3A1F",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.summer",
      name: "Summer",
      hexColors: [
        "0E7C7B", "17A2A0", "00A6A6", "05A87F",
        "E07A5F", "EF476F", "D62246", "E09F3E",
        "C1651A", "118AB2", "0B6E99", "073B4C",
        "3D348B", "6A4C93", "1B9AAA", "F25C54"
      ],
      textColorHex: "FFFFFF",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.autumn",
      name: "Autumn",
      hexColors: [
        "9C2B1E", "B34724", "D2691E", "E08A3C",
        "C9A227", "A67C00", "7A5C1E", "6B4226",
        "8B4513", "A0522D", "5C4033", "7D5A3C",
        "B7410E", "8A3324", "4E6E58", "6E7F4C"
      ],
      textColorHex: "FFF6E9",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.winter",
      name: "Winter",
      hexColors: [
        "CFE8F5", "A9D6EB", "8ABFDC", "BFD7ED",
        "D7E3F4", "AEB8E0", "C3B9DD", "9FB3D9",
        "B8E0DC", "8FCFCB", "D5E5E3", "E2E8F0",
        "C1CBD9", "A3B1C2", "DCE4EC", "B6C6D6"
      ],
      textColorHex: "12283A",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.ocean",
      name: "Ocean",
      hexColors: [
        "03045E", "023E8A", "0077B6", "0096C7",
        "00879B", "006D77", "13505B", "1B4965",
        "2A6F97", "01497C", "014F86", "2C7DA0",
        "468FAF", "1D3557", "457B9D", "0B525B"
      ],
      textColorHex: "FFFFFF",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.sunset",
      name: "Sunset",
      hexColors: [
        "6A0572", "AB2346", "D7263D", "F02D3A",
        "E85D04", "DC2F02", "9D0208", "6A040F",
        "BC3908", "D97706", "C9184A", "A4133C",
        "800F2F", "7B2CBF", "5A189A", "3C096C"
      ],
      textColorHex: "FFFFFF",
      isBuiltIn: true
    ),
    TimetableTheme(
      id: "builtin.monochrome",
      name: "Monochrome",
      hexColors: [
        "1C1C1E", "2C2C2E", "3A3A3C", "48484A",
        "545456", "636366", "6E6E73", "7C7C80",
        "1F2933", "323F4B", "3E4C59", "52606D",
        "616E7C", "2D3436", "414A4F", "4F5B62"
      ],
      textColorHex: "FFFFFF",
      isBuiltIn: true
    )
  ]

  /// Literal lookups so the names are picked up by string extraction.
  static func localizedBuiltInName(for id: String) -> String? {
    switch id {
    case "builtin.default": String(localized: "Default", bundle: .module)
    case "builtin.legacy": String(localized: "Legacy", bundle: .module)
    case "builtin.olive": String(localized: "Olive", bundle: .module)
    case "builtin.cherryBlossom": String(localized: "Cherry Blossom", bundle: .module)
    case "builtin.spring": String(localized: "Spring", bundle: .module)
    case "builtin.summer": String(localized: "Summer", bundle: .module)
    case "builtin.autumn": String(localized: "Autumn", bundle: .module)
    case "builtin.winter": String(localized: "Winter", bundle: .module)
    case "builtin.ocean": String(localized: "Ocean", bundle: .module)
    case "builtin.sunset": String(localized: "Sunset", bundle: .module)
    case "builtin.monochrome": String(localized: "Monochrome", bundle: .module)
    default: nil
    }
  }
}

// MARK: - Authoring

public extension TimetableTheme {
  /// A blank canvas for a new user theme.
  static func makeCustom(name: String) -> TimetableTheme {
    TimetableTheme(
      id: "custom.\(UUID().uuidString)",
      name: name,
      hexColors: TimetableTheme.default.hexColors,
      textColorHex: TimetableTheme.default.textColorHex
    )
  }

  /// A user-owned copy of an existing theme, ready to edit.
  func duplicated(named name: String) -> TimetableTheme {
    TimetableTheme(
      id: "custom.\(UUID().uuidString)",
      name: name,
      hexColors: hexColors,
      textColorHex: textColorHex
    )
  }

  var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hexColors.isEmpty
  }
}
