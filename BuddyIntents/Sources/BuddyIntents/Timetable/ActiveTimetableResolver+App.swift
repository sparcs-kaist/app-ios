//
//  ActiveTimetableResolver+App.swift
//  BuddyIntents
//

import Factory
import BuddyDomain
import BuddyDataCore

public extension ActiveTimetableResolver {
  /// The resolver Siri and Shortcuts use. They run in the app process, so this
  /// goes through the app's timetable use case and shares its authenticated
  /// networking and single coalesced token refresh, rather than refreshing on
  /// its own and racing the app over a rotated refresh token.
  static func app() -> ActiveTimetableResolver? {
    guard let useCase = Container.shared.v2TimetableUseCase() else { return nil }
    return ActiveTimetableResolver(useCase: TimetableUseCaseBackgroundAdapter(useCase))
  }
}
