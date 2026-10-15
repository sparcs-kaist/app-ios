//
//  DeleteClassEventIntent.swift
//  BuddyIntents
//

import AppIntents
import BuddyDomain
import BuddyDataCore

/// "Remove gym from my timetable." Deletes a custom activity from a user-created
/// timetable. Siri confirms first; lectures, academic dates and My Table refuse.
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
      _ = try await ClassEventWriting.useCase()
        .deleteActivity(timetableID: target.timetableID, activityID: target.activityID)
      return .result(dialog: "Removed \(entity.title) from every week.")
    } catch {
      throw await refusal(for: error)
    }
  }
}
