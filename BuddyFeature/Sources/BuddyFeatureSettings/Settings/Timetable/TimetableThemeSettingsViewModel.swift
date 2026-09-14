//
//  TimetableThemeSettingsViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import Foundation
import Observation
import BuddyDomain

@MainActor
@Observable
public final class TimetableThemeSettingsViewModel {
  public private(set) var customThemes: [TimetableTheme] = []
  public private(set) var selectedThemeID: String = TimetableTheme.default.id

  private let store: TimetableThemeStore

  public init(store: TimetableThemeStore = TimetableThemeStore()) {
    self.store = store
    reload()
  }

  public var builtInThemes: [TimetableTheme] { TimetableTheme.builtIn }

  public var selectedTheme: TimetableTheme {
    (builtInThemes + customThemes).first { $0.id == selectedThemeID } ?? .default
  }

  public func reload() {
    customThemes = store.customThemes
    selectedThemeID = store.selectedThemeID ?? TimetableTheme.default.id
  }

  public func select(_ theme: TimetableTheme) {
    store.select(id: theme.id)
    selectedThemeID = theme.id
  }

  public func save(_ theme: TimetableTheme) {
    store.save(theme)
    reload()
  }

  /// Saves a theme and makes it the active one.
  public func saveAndSelect(_ theme: TimetableTheme) {
    store.save(theme)
    store.select(id: theme.id)
    reload()
  }

  public func delete(_ theme: TimetableTheme) {
    store.delete(id: theme.id)
    reload()
  }

  /// A user-owned copy, named so it doesn't read as the provided theme.
  public func duplicate(_ theme: TimetableTheme) -> TimetableTheme {
    theme.duplicated(named: String(localized: "\(theme.displayName) Copy", bundle: .module))
  }
}
