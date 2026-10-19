import Foundation

/// A timetable a widget can be configured with: a user-created table, or a
/// semester's My Table.
///
/// Widget configurations persist an `Int` entity identifier, and server table IDs
/// are positive. My Table has no server ID, so it is encoded as a negative number
/// derived from its semester. Existing configurations keep resolving unchanged.
public enum TimetableReference: Hashable, Sendable {
  case table(id: Int)
  case myTable(year: Int, semester: SemesterType)

  public init?(entityID: Int) {
    if entityID > 0 {
      self = .table(id: entityID)
      return
    }
    let encoded = -entityID
    guard let semester = Self.semesters.first(where: { Self.index(of: $0) == encoded % 10 }) else {
      return nil
    }
    self = .myTable(year: encoded / 10, semester: semester)
  }

  public var entityID: Int {
    switch self {
    case .table(let id): id
    case .myTable(let year, let semester): -(year * 10 + Self.index(of: semester))
    }
  }

  private static let semesters: [SemesterType] = [.spring, .summer, .autumn, .winter]

  /// 1-based, so no semester encodes to zero.
  private static func index(of semester: SemesterType) -> Int {
    (semesters.firstIndex(of: semester) ?? 0) + 1
  }
}
