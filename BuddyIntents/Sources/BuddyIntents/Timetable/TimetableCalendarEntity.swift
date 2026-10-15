//
//  TimetableCalendarEntity.swift
//  BuddyIntents
//

import AppIntents
import BuddyDomain
import BuddyDataCore

/// One of the two calendars Buddy exposes to Siri: the active timetable, and the
/// read-only KAIST academic calendar. IDs stay the same when the user switches
/// timetables; write intents resolve the concrete table when they run.
@available(iOS 27.0, *)
@AppEntity(schema: .calendar.calendar)
struct TimetableCalendarEntity: IndexedEntity, SyncableEntity {
  static let defaultQuery = TimetableCalendarQuery()

  /// A `ClassEvent.CalendarKind` raw value.
  let id: String
  var title: String

  var kind: ClassEvent.CalendarKind { ClassEvent.CalendarKind(rawValue: id) ?? .timetable }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(title)",
      image: .init(systemName: kind == .academic ? "graduationcap" : "calendar")
    )
  }

  init(kind: ClassEvent.CalendarKind, active: ActiveTimetable?) {
    self.id = kind.rawValue
    switch kind {
    case .timetable:
      self.title = active?.title ?? String(localized: "Timetable")
    case .academic:
      self.title = String(localized: "KAIST Academic Calendar")
    }
  }
}

@available(iOS 27.0, *)
struct TimetableCalendarQuery: EnumerableEntityQuery {
  func entities(for identifiers: [String]) async throws -> [TimetableCalendarEntity] {
    try await allEntities().filter { identifiers.contains($0.id) }
  }

  func allEntities() async throws -> [TimetableCalendarEntity] {
    let active = await ActiveTimetableResolver.app()?.resolve()
    return ClassEvent.CalendarKind.allCases.map { TimetableCalendarEntity(kind: $0, active: active) }
  }
}
