import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Reads and writes the timetable theme selection in the shared app group, so the
/// app, its widgets, and the Next Class widget all resolve the same colour sets.
public struct TimetableThemeStore {
  public static let appGroupIdentifier = "group.org.sparcs.soap"
  /// Shared with `@AppStorage` in the UI layer, so keys must stay in sync.
  public static let selectedThemeIDKey = "timetable.theme.selectedID"
  public static let customThemesKey = "timetable.theme.customThemes"

  /// One shared instance, not a fresh `UserDefaults` per access: `@AppStorage`
  /// only observes the object it was handed, so a write through a different
  /// instance of the same suite persists without ever invalidating the view.
  ///
  /// Falls back to `.standard` only when the app group is unavailable (tests).
  ///
  /// `nonisolated(unsafe)` because `UserDefaults` isn't `Sendable`, though it is
  /// documented as thread-safe and widgets read it off the main actor.
  public nonisolated(unsafe) static let sharedDefaults: UserDefaults =
    UserDefaults(suiteName: appGroupIdentifier) ?? .standard

  private let defaults: UserDefaults

  public init(defaults: UserDefaults? = nil) {
    self.defaults = defaults ?? Self.sharedDefaults
  }

  // MARK: - Reading

  public var customThemes: [TimetableTheme] {
    Self.decodeCustomThemes(defaults.data(forKey: Self.customThemesKey))
  }

  public var selectedThemeID: String? {
    defaults.string(forKey: Self.selectedThemeIDKey)
  }

  /// Every theme the user can pick from, collections ones first.
  public var allThemes: [TimetableTheme] {
    TimetableTheme.builtIn + customThemes
  }

  /// The theme chosen in Settings.
  public var selectedTheme: TimetableTheme {
    theme(id: selectedThemeID) ?? .default
  }

  public func theme(id: String?) -> TimetableTheme? {
    guard let id else { return nil }
    return allThemes.first { $0.id == id }
  }

  /// Resolves a widget's configured theme, falling back to the app-wide choice
  /// when the widget has no explicit selection (or it was since deleted).
  public func resolvedTheme(id: String?) -> TimetableTheme {
    theme(id: id) ?? selectedTheme
  }

  public static func decodeCustomThemes(_ data: Data?) -> [TimetableTheme] {
    guard let data, !data.isEmpty else { return [] }
    return (try? JSONDecoder().decode([TimetableTheme].self, from: data)) ?? []
  }

  // MARK: - Writing

  public func select(id: String) {
    defaults.set(id, forKey: Self.selectedThemeIDKey)
    reloadWidgets()
  }

  /// Inserts or replaces one of the user's own themes. Collections themes are ignored.
  public func save(_ theme: TimetableTheme) {
    guard !theme.isBuiltIn else { return }
    var themes = customThemes
    if let index = themes.firstIndex(where: { $0.id == theme.id }) {
      themes[index] = theme
    } else {
      themes.append(theme)
    }
    write(themes)
  }

  public func delete(id: String) {
    store(customThemes.filter { $0.id != id })
    // Deleting the active theme drops back to the default rather than leaving a
    // dangling selection that widgets would have to guess about.
    if selectedThemeID == id {
      defaults.removeObject(forKey: Self.selectedThemeIDKey)
    }
    reloadWidgets()
  }

  private func write(_ themes: [TimetableTheme]) {
    store(themes)
    reloadWidgets()
  }

  private func store(_ themes: [TimetableTheme]) {
    guard let data = try? JSONEncoder().encode(themes) else { return }
    defaults.set(data, forKey: Self.customThemesKey)
  }

  private func reloadWidgets() {
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    #endif
  }
}

public extension TimetableTheme {
  /// The theme chosen in Settings. Widgets resolve their own theme from their
  /// configuration instead, via ``TimetableThemeStore/resolvedTheme(id:)``.
  static var current: TimetableTheme {
    TimetableThemeStore().selectedTheme
  }
}
