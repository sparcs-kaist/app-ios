//
//  OpenClassEventIntent.swift
//  BuddyIntents
//

import AppIntents
import BuddyDomain

/// Opens Buddy on the Timetable tab for a class, activity or academic date.
@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenClassEventIntent {
  var target: ClassEventEntity

  @MainActor
  func perform() async throws -> some IntentResult {
    // Pending as well as posted: on a cold launch the main screen isn't up yet.
    PendingDeepLink.post(.timetable)
    return .result()
  }
}
