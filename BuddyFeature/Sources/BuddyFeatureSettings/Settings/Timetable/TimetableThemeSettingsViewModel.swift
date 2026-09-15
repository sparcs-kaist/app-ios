//
//  TimetableThemeSettingsViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import Foundation
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
public final class TimetableThemeSettingsViewModel {
  public private(set) var customThemes: [TimetableTheme] = []
  public private(set) var selectedThemeID: String = TimetableTheme.default.id

  public private(set) var isImporting = false
  public var importedTheme: TimetableTheme?
  public var sharingError: String?

  @ObservationIgnored
  @Injected(\.timetableThemeUseCase) private var themeUseCase: TimetableThemeUseCaseProtocol?

  public func fetchSharedTheme(code: String) async {
    guard !isImporting, let code = TimetableThemeShareCode.normalized(code) else { return }
    isImporting = true
    importedTheme = nil
    sharingError = nil
    defer { isImporting = false }
    do {
      guard let themeUseCase else { throw URLError(.unknown) }
      importedTheme = try await themeUseCase.fetch(code: code)
    } catch NetworkError.notFound {
      sharingError = String(localized: "No theme found for this code.", bundle: .module)
    } catch {
      sharingError = String(localized: "Could not load this theme. Please try again.", bundle: .module)
    }
  }

  private let store: TimetableThemeStore

  /// Nil on platforms without a paired watch.
  @ObservationIgnored
  @Injected(\.sessionBridgeService) private var sessionBridgeService: SessionBridgeServiceProtocol?

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
    syncToWatch()
  }

  public func save(_ theme: TimetableTheme) {
    store.save(theme)
    reload()
    // Editing the active theme changes its colours without changing the
    // selection, so the watch needs the new version either way.
    syncToWatch()
  }

  /// Saves a theme and makes it the active one.
  public func saveAndSelect(_ theme: TimetableTheme) {
    store.save(theme)
    store.select(id: theme.id)
    reload()
    syncToWatch()
  }

  public func delete(_ theme: TimetableTheme) {
    store.delete(id: theme.id)
    reload()
    syncToWatch()
  }

  /// The watch mirrors the phone's choice rather than having its own setting.
  private func syncToWatch() {
    sessionBridgeService?.updateSelectedTheme()
  }

  /// A user-owned copy, named so it doesn't read as the collections theme.
  public func duplicate(_ theme: TimetableTheme) -> TimetableTheme {
    theme.duplicated(named: String(localized: "\(theme.displayName) Copy", bundle: .module))
  }
}
