//
//  ClassEventSchemaTypes.swift
//  BuddyIntents
//
//  Supporting types the calendar App Schema requires. Buddy fills only what its
//  timetable carries; the rest stays empty rather than guessed at.
//

import AppIntents
import GeoToolbox

@available(iOS 27.0, *)
@AppEntity(schema: .calendar.attendee)
struct ClassAttendeeEntity: TransientAppEntity {
  var person: IntentPerson
  var status: ClassAttendeeStatus?
  var isAttendanceOptional: Bool
  var type: ClassAttendeeType?

  init() {
    person = IntentPerson(identifier: .unknown, name: .unknown, handle: nil)
    status = nil
    isAttendanceOptional = false
    type = nil
  }

  var displayRepresentation: DisplayRepresentation {
    switch person.name {
    case .displayName(let name): DisplayRepresentation(title: "\(name)")
    case .components(let components): DisplayRepresentation(title: "\(components.formatted())")
    default: "Attendee"
    }
  }
}

@available(iOS 27.0, *)
@AppEnum(schema: .calendar.eventStatus)
enum ClassEventStatus: String {
  case confirmed
  case tentative
  case cancelled

  static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .confirmed: "Confirmed",
    .tentative: "Tentative",
    .cancelled: "Cancelled",
  ]
}

@available(iOS 27.0, *)
@AppEnum(schema: .calendar.eventSpan)
enum ClassEventSpan: String {
  case this
  case future
  case all

  static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .this: "This Event Only",
    .future: "Future Events",
    .all: "All Events",
  ]
}

@available(iOS 27.0, *)
@AppEnum(schema: .calendar.attendeeStatus)
enum ClassAttendeeStatus: String {
  case accepted
  case declined
  case tentative

  static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .accepted: "Accepted",
    .declined: "Declined",
    .tentative: "Tentative",
  ]
}

@available(iOS 27.0, *)
@AppEnum(schema: .calendar.attendeeType)
enum ClassAttendeeType: String {
  case person

  static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .person: "Person",
  ]
}

@available(iOS 27.0, *)
@UnionValue
enum ClassEventLocation {
  case place(PlaceDescriptor)
  case address(String)

  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Location"
  static let caseDisplayRepresentations: [Cases: DisplayRepresentation] = [
    .place: "Place",
    .address: "Address",
  ]

  /// The location as the plain text a timetable activity stores.
  var text: String? {
    switch self {
    case .place(let place): place.commonName
    case .address(let address): address
    }
  }
}

@available(iOS 27.0, *)
@UnionValue
enum ClassEventAlarm {
  case duration(Duration)
  case date(Date)

  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Alert"
  static let caseDisplayRepresentations: [Cases: DisplayRepresentation] = [
    .duration: "Duration",
    .date: "Date",
  ]
}
