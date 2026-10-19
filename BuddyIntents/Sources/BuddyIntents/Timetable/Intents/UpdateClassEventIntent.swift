//
//  UpdateClassEventIntent.swift
//  BuddyIntents
//

import AppIntents
import BuddyDomain
import BuddyDataCore

/// "Move my gym session to 5pm." Changes a custom activity in a user-created
/// timetable. Lectures, academic dates and My Table can't change.
@available(iOS 27.0, *)
@AppIntent(schema: .calendar.updateEvent)
struct UpdateClassEventIntent {
  static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
  /// Nobody holding a locked phone can change the timetable.
  static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  var event: ClassEventEntity
  var title: String?
  var attendees: [ClassAttendeeEntity]?
  var startDate: Date?
  var endDate: Date?
  var isAllDay: Bool?
  var calendar: TimetableCalendarEntity?
  var recurrence: Calendar.RecurrenceRule?
  var note: String?
  var location: ClassEventLocation?
  var span: ClassEventSpan?

  func perform() async throws -> some ReturnsValue<ClassEventEntity> & ProvidesDialog {
    do {
      if calendar?.kind == .academic { throw ClassEventWriteError.academicIsReadOnly }
      let target = try ClassEventWritePolicy.activity(for: event.kind)
      try ClassEventWritePolicy.requireEveryWeek(thisWeekOnly: span == .this)
      let useCase = try ClassEventWriting.useCase()
      let active = try await ClassEventWriting.activeTimetable()
      let table = try await useCase.getTable(id: target.timetableID)
      guard let activity = table.activities.first(where: { $0.id == target.activityID }) else {
        throw ClassEventWriteError.activityNotFound
      }

      // Unspecified values keep their current setting; a new start keeps the length.
      let newStart = startDate ?? event.startDate
      let newEnd = endDate ?? newStart.addingTimeInterval(event.endDate.timeIntervalSince(event.startDate))
      let moved = try ClassEventWritePolicy.draft(
        title: title ?? activity.title,
        startDate: newStart,
        endDate: newEnd,
        location: location?.text ?? activity.location,
        isAllDay: isAllDay ?? false,
        recurrence: recurrence
      )
      // Only this event's time range moves; the activity's other ranges stay.
      let draft = try ClassEventWritePolicy.updating(activity, timeIndex: target.timeIndex, with: moved)

      let updated = try await useCase.saveActivity(
        timetableID: target.timetableID,
        activityID: target.activityID,
        draft: draft
      )
      guard let entity = ClassEventWriting.entity(activityID: target.activityID, timeIndex: target.timeIndex,
                                                   in: updated, timetableID: target.timetableID, active: active) else {
        throw ClassEventWriteError.activityNotFound
      }
      return .result(value: entity, dialog: "Updated \(entity.title) for every week.")
    } catch {
      throw await refusal(for: error)
    }
  }
}
