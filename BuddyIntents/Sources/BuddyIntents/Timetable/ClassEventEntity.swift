//
//  ClassEventEntity.swift
//  BuddyIntents
//

import AppIntents
import CoreSpotlight
import Factory
import BuddyDomain
import BuddyDataCore

/// A class, custom activity or academic date from the active timetable, as a
/// calendar event Siri can answer questions about.
@available(iOS 27.0, *)
@AppEntity(schema: .calendar.event)
struct ClassEventEntity: IndexedEntity, SyncableEntity {
  static let defaultQuery = ClassEventQuery()

  /// A `ClassEvent` identifier. Built from server IDs, so stable across devices.
  let id: String
  var calendar: TimetableCalendarEntity
  var title: String
  var startDate: Date
  var endDate: Date
  var isAllDay: Bool
  var recurrence: Calendar.RecurrenceRule?
  var note: AttributedString?
  var travelTime: Duration?
  var location: ClassEventLocation?
  var virtualLocation: URL?
  var status: ClassEventStatus?
  var alarms: [ClassEventAlarm]
  var organizers: [IntentPerson]
  var attendees: [ClassAttendeeEntity]

  var kind: ClassEvent.Kind { ClassEvent.kind(of: id) ?? .academic }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(title)",
      subtitle: "\(Self.subtitle(startDate: startDate, endDate: endDate, isAllDay: isAllDay, location: location?.text))",
      image: .init(systemName: Self.symbol(for: kind))
    )
  }

  /// Adds bilingual search terms (e.g. 종강, 드랍, 수업) so Siri matches the way
  /// students actually ask, not only the event's title.
  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = defaultAttributeSet
    let keywords = ClassEventBuilder.keywords(forEventID: id)
    attributes.keywords = keywords
    attributes.alternateNames = keywords
    return attributes
  }

  init(_ event: ClassEvent, calendar: TimetableCalendarEntity) {
    self.id = event.id
    self.calendar = calendar
    self.title = event.title
    self.startDate = event.startDate
    self.endDate = event.endDate
    self.isAllDay = event.isAllDay
    self.recurrence = event.recurrence
    self.note = event.note.map { AttributedString($0) }
    self.travelTime = nil
    self.location = event.location.map { .address($0) }
    self.virtualLocation = nil
    self.status = nil
    self.alarms = []
    self.organizers = []
    self.attendees = []
  }

  /// Every event of the active timetable plus the semester's academic dates.
  static func all(for active: ActiveTimetable) -> [ClassEventEntity] {
    let timetable = TimetableCalendarEntity(kind: .timetable, active: active)
    let academic = TimetableCalendarEntity(kind: .academic, active: active)
    return active.events.map { ClassEventEntity($0, calendar: timetable) }
      + ClassEventBuilder.academicEvents(for: active.semester).map { ClassEventEntity($0, calendar: academic) }
  }

  // MARK: - Display

  /// "Thu 14:30–16:00 · E11 304", in KAIST time.
  static func subtitle(startDate: Date, endDate: Date, isAllDay: Bool, location: String?) -> String {
    let timeZone = Calendar.kaist.timeZone
    let when: String
    if isAllDay {
      when = startDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: timeZone))
    } else {
      let day = startDate.formatted(Date.FormatStyle(timeZone: timeZone).weekday(.abbreviated))
      let time = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone)
      when = "\(day) \(startDate.formatted(time))–\(endDate.formatted(time))"
    }
    guard let location, !location.isEmpty else { return when }
    return "\(when) · \(location)"
  }

  private static func symbol(for kind: ClassEvent.Kind) -> String {
    switch kind {
    case .lecture: "book"
    case .activity: "figure.walk"
    case .academic: "graduationcap"
    }
  }
}

@available(iOS 27.0, *)
struct ClassEventQuery: EnumerableEntityQuery, IndexedEntityQuery {
  func entities(for identifiers: [String]) async throws -> [ClassEventEntity] {
    try await allEntities().filter { identifiers.contains($0.id) }
  }

  func allEntities() async throws -> [ClassEventEntity] {
    guard let active = await ActiveTimetableResolver.app()?.resolve() else { return [] }
    return ClassEventEntity.all(for: active)
  }

  /// Through the app's indexer, so the rebuild queues behind sign-out's clear
  /// rather than racing it.
  func reindexEntities(for identifiers: [String], indexDescription: CSSearchableIndexDescription) async throws {
    Container.shared.timetableIndexingService()?.scheduleReindex()
  }

  func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
    Container.shared.timetableIndexingService()?.scheduleReindex()
  }
}
