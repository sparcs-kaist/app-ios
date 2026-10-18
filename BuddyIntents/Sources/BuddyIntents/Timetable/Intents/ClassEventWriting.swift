//
//  ClassEventWriting.swift
//  BuddyIntents
//

import AppIntents
import Factory
import BuddyDomain
import BuddyDataCore

/// Couldn't reach the timetable at all, e.g. signed out.
enum ClassEventIntentError: LocalizedError {
  case timetableUnavailable

  var errorDescription: String? {
    String(localized: "Buddy couldn't load your timetable. Open Buddy and try again.")
  }
}

/// Shared plumbing for Siri's create, update and delete.
@available(iOS 27.0, *)
enum ClassEventWriting {
  /// The app's timetable use case. Writes run in the app process, where the
  /// dependency container is registered.
  static func useCase() throws -> TimetableUseCaseProtocol {
    guard let useCase = Container.shared.v2TimetableUseCase() else {
      throw ClassEventIntentError.timetableUnavailable
    }
    return useCase
  }

  static func activeTimetable() async throws -> ActiveTimetable {
    guard let active = await ActiveTimetableResolver.app()?.resolve() else {
      throw ClassEventIntentError.timetableUnavailable
    }
    return active
  }

  /// The next meeting of one of the activity's time ranges after a write, from
  /// the timetable the write returned; its first meeting if the semester's
  /// meetings are all past.
  static func entity(
    activityID: Int,
    timeIndex: Int = 0,
    in timetable: Timetable,
    timetableID: Int,
    active: ActiveTimetable
  ) -> ClassEventEntity? {
    let id = ClassEvent.activityID(timetableID: timetableID, activityID: activityID, timeIndex: timeIndex)
    let calendar = TimetableCalendarEntity(kind: .timetable, active: active)
    let meetings = ClassEventBuilder.occurrences(for: timetable, timetableID: timetableID, semester: active.semester)
      .filter { $0.id.hasPrefix(id + "@") }
    let now = Date()
    return (meetings.first { $0.endDate > now } ?? meetings.first)
      .map { ClassEventEntity($0, calendar: calendar) }
  }
}

@available(iOS 27.0, *)
extension AppIntent {
  /// While My Table is active, Siri explains why it can't change it and offers to
  /// open the Timetable tab, where Duplicate My Table lives. It never duplicates
  /// My Table itself. Other errors pass through unchanged.
  func refusal(for error: Error) async -> Error {
    guard let writeError = error as? ClassEventWriteError,
          writeError == .myTableIsReadOnly,
          systemContext.currentMode.canContinueInForeground else {
      return error
    }
    do {
      try await continueInForeground("\(writeError.localizedDescription)", alwaysConfirm: true)
    } catch {
      // Declined: leave the app as it was.
      return error
    }
    // Only now that the user chose to open Buddy does the tab change.
    await PendingDeepLink.post(.timetable)
    return writeError
  }
}
