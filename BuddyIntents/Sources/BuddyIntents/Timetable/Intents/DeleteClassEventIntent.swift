//
//  DeleteClassEventIntent.swift
//  BuddyIntents
//

import AppIntents
import BuddyDomain
import BuddyDataCore

/// "Remove gym from my timetable." Deletes a custom activity's weekly meeting from a
/// user-created timetable, and the activity itself with its last meeting. Siri
/// confirms first; lectures, academic dates and My Table refuse.
@available(iOS 27.0, *)
@AppIntent(schema: .calendar.deleteEvent)
struct DeleteClassEventIntent {
  static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
  /// Nobody holding a locked phone can delete from the timetable.
  static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  var entity: ClassEventEntity
  /// One week only is refused: every meeting is the same weekly slot.
  var span: ClassEventSpan?

  func perform() async throws -> some IntentResult & ProvidesDialog {
    do {
      let target = try ClassEventWritePolicy.activity(for: entity.kind)
      try ClassEventWritePolicy.requireEveryWeek(thisWeekOnly: span == .this)
      let useCase = try ClassEventWriting.useCase()
      let table = try await useCase.getTable(id: target.timetableID)
      guard let activity = table.activities.first(where: { $0.id == target.activityID }) else {
        throw ClassEventWriteError.activityNotFound
      }
      // An activity meeting at several times loses only this one.
      if let remaining = try ClassEventWritePolicy.removing(timeIndex: target.timeIndex, from: activity) {
        _ = try await useCase.saveActivity(timetableID: target.timetableID, activityID: target.activityID, draft: remaining)
      } else {
        _ = try await useCase.deleteActivity(timetableID: target.timetableID, activityID: target.activityID)
      }
      return .result(dialog: "Removed \(entity.title) from every week.")
    } catch {
      throw await refusal(for: error)
    }
  }
}
