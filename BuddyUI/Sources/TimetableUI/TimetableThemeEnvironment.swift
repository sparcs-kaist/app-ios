//
//  TimetableThemeEnvironment.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import SwiftUI
import BuddyDomain

public extension EnvironmentValues {
  /// The colour set every timetable cell, dot, and swatch renders with.
  ///
  /// The app injects the user's choice with ``SwiftUI/View/timetableThemeFromSettings()``;
  /// widgets inject the theme picked in their own configuration instead.
  @Entry var timetableTheme: TimetableTheme = .default
}

public extension View {
  /// Renders the hierarchy with an explicit theme.
  func timetableTheme(_ theme: TimetableTheme) -> some View {
    environment(\.timetableTheme, theme)
  }

  /// Follows the theme chosen in Settings, updating live when the selection or
  /// the user's own themes change.
  func timetableThemeFromSettings() -> some View {
    modifier(SettingsTimetableThemeModifier())
  }
}

private struct SettingsTimetableThemeModifier: ViewModifier {
  @AppStorage(TimetableThemeStore.selectedThemeIDKey, store: TimetableThemeStore.sharedDefaults)
  private var selectedThemeID: String = TimetableTheme.default.id

  // Read so that editing a user theme re-renders the grid, not just selecting one.
  @AppStorage(TimetableThemeStore.customThemesKey, store: TimetableThemeStore.sharedDefaults)
  private var customThemesData: Data = Data()

  func body(content: Content) -> some View {
    let themes = TimetableTheme.builtIn + TimetableThemeStore.decodeCustomThemes(customThemesData)
    return content
      .timetableTheme(themes.first { $0.id == selectedThemeID } ?? .default)
  }
}
