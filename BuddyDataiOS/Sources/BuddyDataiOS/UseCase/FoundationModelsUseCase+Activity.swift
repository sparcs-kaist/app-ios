//
//  FoundationModelsUseCase+Activity.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation
import FoundationModels
import BuddyDomain

/// The activity form's fields, as the model fills them in. Everything but the
/// title is optional, so a description that leaves something out leaves the
/// form's own value alone rather than having the model guess one.
@Generable(description: "A weekly activity on a university student's timetable")
private struct GeneratedActivity {
  @Guide(description: "A short title for the activity in the words the person used, without the day, time or place.")
  var title: String

  @Guide(description: "Where the activity happens, only if the person names a place such as a building or room.")
  var location: String?

  @Guide(description: "Every day of the week it happens on, only if the person names them: all seven for every day, Monday to Friday for weekdays.")
  var days: [GeneratedDay]

  @Guide(description: "The hour it starts on a 24-hour clock, from 0 to 23, only if given.")
  var startHour: Int?

  @Guide(description: "The minute past the hour it starts, from 0 to 59.")
  var startMinute: Int?

  @Guide(description: "The hour it ends on a 24-hour clock, from 0 to 23, only if given.")
  var endHour: Int?

  @Guide(description: "The minute past the hour it ends, from 0 to 59.")
  var endMinute: Int?

  @Guide(description: "How long it lasts in minutes, only if given as a length rather than an end time.")
  var durationMinutes: Int?
}

@Generable
private enum GeneratedDay {
  case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

extension FoundationModelsUseCase {
  /// Model-facing, so deliberately not localised. No worked examples, which
  /// leaked into answers when tried for timetable themes.
  private static let activityInstructions = """
    You fill in a form for a weekly activity on a university student's \
    timetable, from a description they type.

    Every activity repeats weekly. Give it a short title in the words they \
    used, leaving out the day, the time, the place and words that only say it \
    repeats, such as every or weekly. Give the place only if they say where it \
    happens: the name of a club, team or event is not a place.

    Give the days of the week only if they name them, every one they name: \
    all seven for every day, Monday to Friday for weekdays, Saturday and \
    Sunday for weekends. Give times on a 24-hour \
    clock: afternoon and evening times are 12 or more, \
    so 7 in the evening is 19. Give an end time only if they give one, and a \
    length only if they give one instead. Leave out anything they don't say \
    rather than guessing.

    Keep the title and the place in the language they wrote in.
    """

  /// A description far longer than this is a paste, not an activity.
  private static let maximumActivityDescriptionLength = 200

  /// The days and the times come from `ActivityDescriptionScanner` where it
  /// finds them, and from the model only where it doesn't: the model misread
  /// Korean times, and it isn't told today's day, which it answered with
  /// whatever day was named.
  public func parseActivity(_ description: String, today: DayType) async throws -> ParsedActivity {
    guard case .available = SystemLanguageModel.default.availability else {
      throw ActivityParsingError.unavailable
    }
    let request = String(
      description
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .prefix(Self.maximumActivityDescriptionLength)
    )
    guard !request.isEmpty else { throw ActivityParsingError.nothingFound }

    let session = LanguageModelSession(model: .default, instructions: Self.activityInstructions)
    let generated: GeneratedActivity
    do {
      generated = try await session.respond(
        to: "Fill in the activity form for: \(request)",
        generating: GeneratedActivity.self,
        // The same description should fill in the form the same way each time.
        options: GenerationOptions(samplingMode: .greedy)
      ).content
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      throw Self.activityError(for: error)
    }

    var parsed = ParsedActivity(
      title: generated.title,
      location: generated.location,
      days: generated.days.map(Self.dayType),
      startHour: generated.startHour,
      startMinute: generated.startMinute,
      endHour: generated.endHour,
      endMinute: generated.endMinute,
      durationMinutes: generated.durationMinutes
    )
    let days = ActivityDescriptionScanner.days(in: request, today: today)
    if !days.isEmpty {
      parsed.days = days
    }
    let times = ActivityDescriptionScanner.allTimes(in: request)
    if let first = times.first {
      // A length the model read still applies to a start found here.
      func end(from begin: Int, given end: Int?) -> Int? {
        end ?? generated.durationMinutes.flatMap { minutes in
          minutes > 0 ? min(begin + minutes, 24 * 60) : nil
        }
      }
      parsed.begin = first.begin
      parsed.end = end(from: first.begin, given: first.end)
      parsed.laterTimes = times.dropFirst().map { ParsedActivity.Time(begin: $0.begin, end: end(from: $0.begin, given: $0.end)) }
    }
    guard !parsed.isEmpty else { throw ActivityParsingError.nothingFound }
    return parsed
  }

  private static func dayType(_ day: GeneratedDay) -> DayType {
    switch day {
    case .monday: .mon
    case .tuesday: .tue
    case .wednesday: .wed
    case .thursday: .thu
    case .friday: .fri
    case .saturday: .sat
    case .sunday: .sun
    }
  }

  /// As in `generationError(for:)`, iOS 27 and iOS 26 throw different types.
  private static func activityError(for error: any Error) -> ActivityParsingError {
    if #available(iOS 27, *), let error = error as? LanguageModelError {
      switch error {
      case .guardrailViolation, .refusal: return .unsafeRequest
      default: return .failed
      }
    }
    if let error = error as? LanguageModelSession.GenerationError {
      switch error {
      case .guardrailViolation, .refusal: return .unsafeRequest
      default: return .failed
      }
    }
    return .failed
  }
}
