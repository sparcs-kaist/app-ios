//
//  ClassesOnDayIntent.swift
//  BuddyIntents
//

import AppIntents
import SwiftUI
import BuddyDomain
import BuddyDataCore

/// The day `ClassesOnDayIntent` lists, in KAIST time.
public enum ClassDay: String, AppEnum {
  case today
  case tomorrow

  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Day"
  public static let caseDisplayRepresentations: [ClassDay: DisplayRepresentation] = [
    .today: "Today",
    .tomorrow: "Tomorrow",
  ]

  func date(from now: Date, calendar: Calendar = .kaist) -> Date {
    switch self {
    case .today: now
    case .tomorrow: calendar.date(byAdding: .day, value: 1, to: now) ?? now
    }
  }
}

/// "What lectures do I have tomorrow?" Lists the active timetable's classes and
/// activities on one day.
///
/// Without it, Siri matched that question to `MyLecturesIntent` and read out the
/// whole semester. A plain intent with fixed phrases, like `MyLecturesIntent`.
public struct ClassesOnDayIntent: AppIntent {
  public static let title: LocalizedStringResource = "Get Classes on a Day"
  public static let description = IntentDescription(
    "Lists your classes and activities for today or tomorrow.",
    categoryName: "Buddy"
  )
  public static let supportedModes: IntentModes = [.background]
  /// Nobody holding a locked phone can hear the timetable read out.
  public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  @Parameter(title: "Day", default: .today)
  public var day: ClassDay

  public static var parameterSummary: some ParameterSummary {
    Summary("Get classes \(\.$day)")
  }

  public init() {}

  public func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
    guard let active = await ActiveTimetableResolver.app()?.resolve() else {
      return .result(
        dialog: "Buddy couldn't load your timetable. Open Buddy and try again.",
        view: ClassesOnDaySnippetView(events: [])
      )
    }

    let calendar = Calendar.kaist
    let date = day.date(from: .now, calendar: calendar)
    let events = active.events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    let view = ClassesOnDaySnippetView(events: events)

    guard !events.isEmpty else {
      switch day {
      case .today: return .result(dialog: "You have no classes today.", view: view)
      case .tomorrow: return .result(dialog: "You have no classes tomorrow.", view: view)
      }
    }

    let time = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: calendar.timeZone)
    let list = events
      .map { String(localized: "\($0.title) at \($0.startDate.formatted(time))") }
      .formatted(.list(type: .and))
    switch day {
    case .today: return .result(dialog: "Today you have \(list).", view: view)
    case .tomorrow: return .result(dialog: "Tomorrow you have \(list).", view: view)
    }
  }
}

struct ClassesOnDaySnippetView: View {
  let events: [ClassEvent]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(events) { event in
        VStack(alignment: .leading, spacing: 2) {
          Text(event.title)
            .fontWeight(.semibold)
            .lineLimit(1)
          Text(Self.subtitle(for: event))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
  }

  /// "14:30–16:00 · E11 304", in KAIST time.
  private static func subtitle(for event: ClassEvent) -> String {
    let time = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: Calendar.kaist.timeZone)
    let when = "\(event.startDate.formatted(time))–\(event.endDate.formatted(time))"
    guard let location = event.location, !location.isEmpty else { return when }
    return "\(when) · \(location)"
  }
}
