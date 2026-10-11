//
//  CreateClassEventIntent.swift
//  BuddyIntents
//

import AppIntents
import BuddyDomain
import BuddyDataCore

/// "Add gym on Friday at 3pm to my timetable." Adds a weekly custom activity to
/// the active timetable when it's one the user created.
@available(iOS 27.0, *)
@AppIntent(schema: .calendar.createEvent)
struct CreateClassEventIntent {
  static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
  /// Nobody holding a locked phone can add to the timetable.
  static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  var title: String
  var startDate: Date
  var endDate: Date?
  var location: ClassEventLocation?
  var calendar: TimetableCalendarEntity
  var isAllDay: Bool
  var recurrence: Calendar.RecurrenceRule?
  var attendees: [ClassAttendeeEntity]
  var note: AttributedString?

  func perform() async throws -> some ReturnsValue<ClassEventEntity> & ProvidesDialog {
    do {
      let active = try await ClassEventWriting.activeTimetable()
      let timetableID = try ClassEventWritePolicy.tableForNewActivity(
        activeTableID: active.userTableID,
        calendar: calendar.kind
      )
      let draft = try ClassEventWritePolicy.draft(
        title: title,
        startDate: startDate,
        endDate: endDate,
        location: location?.text,
        isAllDay: isAllDay,
        recurrence: recurrence
      )

      let updated = try await ClassEventWriting.useCase()
        .saveActivity(timetableID: timetableID, activityID: nil, draft: draft)
      // The server assigns the ID. Overlaps are rejected, so the new slot's time is unique.
      guard let created = updated.activities.first(where: {
              $0.day == draft.day && $0.begin == draft.begin && $0.end == draft.end
            }),
            let entity = ClassEventWriting.entity(activityID: created.id, in: updated,
                                                   timetableID: timetableID, active: active) else {
        throw ClassEventIntentError.timetableUnavailable
      }
      return .result(value: entity, dialog: "Added \(entity.title) to \(active.title).")
    } catch {
      throw await refusal(for: error)
    }
  }
}
