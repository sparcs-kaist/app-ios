import Foundation

/// The iOS app's last selection, independent of widget and watch preferences.
public struct TimetableSelectionStore {
  private let defaults: UserDefaults
  private static let key = "timetable.lastSelection"

  public struct Selection: Codable, Equatable {
    public let year: Int
    public let semester: SemesterType
    /// Nil represents My Table.
    public let timetableID: Int?

    public func matches(_ semester: Semester) -> Bool {
      year == semester.year && self.semester == semester.semesterType
    }
  }

  public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

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
}
