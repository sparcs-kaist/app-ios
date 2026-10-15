import Foundation

/// The iOS app's last selection, independent of widget and watch preferences.
///
/// Stored in the app group so widgets and App Intents, which run outside the app
/// process, resolve the same active timetable as the Timetable tab.
public struct TimetableSelectionStore {
  private let defaults: UserDefaults
  private static let key = "timetable.lastSelection"
  private static let appGroup = "group.org.sparcs.soap"

  public struct Selection: Codable, Equatable, Sendable {
    public let year: Int
    public let semester: SemesterType
    /// Nil represents My Table.
    public let timetableID: Int?

    public init(year: Int, semester: SemesterType, timetableID: Int?) {
      self.year = year
      self.semester = semester
      self.timetableID = timetableID
    }

    public func matches(_ semester: Semester) -> Bool {
      year == semester.year && self.semester == semester.semesterType
    }
  }

  public init(defaults: UserDefaults) { self.defaults = defaults }

  /// The shared app-group store, carrying over a selection saved by older builds
  /// in the app's standard defaults.
  public init() { self.defaults = Self.shared }

  /// Created and migrated once per process; `static let` initialisation is
  /// thread-safe, and `UserDefaults` is documented as thread-safe though not
  /// marked `Sendable`.
  nonisolated(unsafe) private static let shared: UserDefaults = {
    let shared = UserDefaults(suiteName: appGroup) ?? .standard
    migrate(from: .standard, to: shared)
    return shared
  }()

  public var selection: Selection? {
    guard let data = defaults.data(forKey: Self.key) else { return nil }
    return try? JSONDecoder().decode(Selection.self, from: data)
  }

  public func save(semester: Semester, timetableID: Int?) {
    let selection = Selection(year: semester.year, semester: semester.semesterType, timetableID: timetableID)
    guard let data = try? JSONEncoder().encode(selection) else { return }
    defaults.set(data, forKey: Self.key)
  }

  public func clear() { defaults.removeObject(forKey: Self.key) }

  /// Moves a selection from `old` to `new` unless `new` already has one.
  public static func migrate(from old: UserDefaults, to new: UserDefaults) {
    guard old !== new, let data = old.data(forKey: key) else { return }
    if new.data(forKey: key) == nil {
      new.set(data, forKey: key)
    }
    old.removeObject(forKey: key)
  }
}
