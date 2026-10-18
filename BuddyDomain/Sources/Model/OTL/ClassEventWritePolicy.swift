import Foundation

/// Why Siri can't make a timetable change. Each case carries the wording Siri says.
public enum ClassEventWriteError: LocalizedError, Equatable {
  /// My Table follows course registration and is read-only in the app.
  case myTableIsReadOnly
  case lectureIsReadOnly
  case academicIsReadOnly
  case allDayUnsupported
  case nonWeeklyRecurrence
  case spansMultipleDays
  case activityNotFound
  /// Activities are one weekly slot, so a single week can't change on its own.
  case singleWeekUnsupported

  public var errorDescription: String? {
    switch self {
    case .myTableIsReadOnly:
      String(localized: "My Table follows your course registration, so Siri can't change it. In Buddy, duplicate My Table or select one of your own timetables, then try again.", bundle: .module)
    case .lectureIsReadOnly:
      String(localized: "Lectures follow your course registration, so Siri can't change them.", bundle: .module)
    case .academicIsReadOnly:
      String(localized: "The KAIST academic calendar can't be changed.", bundle: .module)
    case .allDayUnsupported:
      String(localized: "Timetable activities need a start and end time.", bundle: .module)
    case .nonWeeklyRecurrence:
      String(localized: "Timetable activities repeat every week.", bundle: .module)
    case .spansMultipleDays:
      String(localized: "An activity must start and end on the same day.", bundle: .module)
    case .activityNotFound:
      String(localized: "That activity is no longer in your timetable.", bundle: .module)
    case .singleWeekUnsupported:
      String(localized: "Timetable activities repeat every week, so Siri can only change every week at once.", bundle: .module)
    }
  }
}

/// The rules Siri's create, update and delete follow. Only custom activities in a
/// user-created timetable can change; Siri never duplicates My Table itself.
public enum ClassEventWritePolicy {
  /// The user table a new activity goes into.
  ///
  /// - Parameter activeTableID: The active timetable's ID, nil when it is My Table.
  public static func tableForNewActivity(activeTableID: Int?, calendar: ClassEvent.CalendarKind) throws -> Int {
    guard calendar == .timetable else { throw ClassEventWriteError.academicIsReadOnly }
    guard let activeTableID else { throw ClassEventWriteError.myTableIsReadOnly }
    return activeTableID
  }

  /// The table, activity and time range an update or delete changes.
  public static func activity(for kind: ClassEvent.Kind) throws -> (timetableID: Int, activityID: Int, timeIndex: Int) {
    switch kind {
    case .lecture: throw ClassEventWriteError.lectureIsReadOnly
    case .academic: throw ClassEventWriteError.academicIsReadOnly
    case .activity(nil, _, _): throw ClassEventWriteError.myTableIsReadOnly
    case .activity(let timetableID?, let activityID, let timeIndex): return (timetableID, activityID, timeIndex)
    }
  }

  /// `activity` with the time range at `timeIndex` replaced by `draft`'s times,
  /// keeping its other ranges. An event Siri moves is one weekly meeting, so the
  /// activity's other meetings stay where they are; a move onto several weekdays
  /// becomes a time for each.
  public static func updating(
    _ activity: TimetableActivity,
    timeIndex: Int,
    with draft: TimetableActivityDraft
  ) throws -> TimetableActivityDraft {
    guard activity.times.indices.contains(timeIndex), !draft.times.isEmpty else {
      throw ClassEventWriteError.activityNotFound
    }
    var updated = draft
    updated.times = activity.times
    updated.times.replaceSubrange(timeIndex...timeIndex, with: draft.times)
    guard updated.isValid else { throw TimetableActivityError.overlap }
    return updated
  }

  /// `activity` without the time range at `timeIndex`, or nil when that is its
  /// only range and the whole activity goes.
  public static func removing(timeIndex: Int, from activity: TimetableActivity) throws -> TimetableActivityDraft? {
    guard activity.times.indices.contains(timeIndex) else { throw ClassEventWriteError.activityNotFound }
    guard activity.times.count > 1 else { return nil }
    var draft = activity.draft
    draft.times.remove(at: timeIndex)
    return draft
  }

  /// Siri can target one week's meeting ("cancel gym this Friday"), but each of
  /// an activity's times is a weekly slot. Changing it would affect every week, so a
  /// one-week request is refused rather than silently widened.
  public static func requireEveryWeek(thisWeekOnly: Bool) throws {
    if thisWeekOnly { throw ClassEventWriteError.singleWeekUnsupported }
  }

  /// A weekly activity from Siri's dates, in KAIST time.
  ///
  /// - Parameter endDate: Defaults to one hour after `startDate`.
  public static func draft(
    title: String,
    startDate: Date,
    endDate: Date?,
    location: String?,
    isAllDay: Bool = false,
    recurrence: Calendar.RecurrenceRule? = nil,
    calendar: Calendar = .kaist
  ) throws -> TimetableActivityDraft {
    guard !isAllDay else { throw ClassEventWriteError.allDayUnsupported }
    let weekdays = try recurrence.map(Self.weekdays) ?? []

    let endDate = endDate ?? startDate.addingTimeInterval(60 * 60)
    let dayStart = calendar.startOfDay(for: startDate)
    let begin = Int(startDate.timeIntervalSince(dayStart) / 60)
    let end = Int(endDate.timeIntervalSince(dayStart) / 60)
    guard end <= 24 * 60 else { throw ClassEventWriteError.spansMultipleDays }
    guard let day = ClassEventBuilder.day(ofWeekday: calendar.component(.weekday, from: startDate)) else {
      throw TimetableActivityError.invalidTimeOrTitle
    }
    // The start's own day first, then each other weekday the rule repeats on,
    // all at the start's hours: "every Monday and Wednesday at 7pm".
    var days = [day]
    for weekday in weekdays where !days.contains(weekday) { days.append(weekday) }

    let draft = TimetableActivityDraft(
      title: title.trimmingCharacters(in: .whitespacesAndNewlines),
      location: location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
      times: days.map { TimetableActivityTime(day: $0, begin: begin, end: end) }
    )
    guard draft.isValid else { throw TimetableActivityError.invalidTimeOrTitle }
    return draft
  }

  /// The days a weekly rule repeats on beyond its start. Anything else the rule
  /// narrows, such as the second Monday, certain months or set positions, isn't
  /// a weekly slot and is refused rather than quietly dropped.
  private static func weekdays(of recurrence: Calendar.RecurrenceRule) throws -> [DayType] {
    guard recurrence.frequency == .weekly, recurrence.interval == 1,
          recurrence.months.isEmpty, recurrence.daysOfTheMonth.isEmpty, recurrence.daysOfTheYear.isEmpty,
          recurrence.weeks.isEmpty, recurrence.hours.isEmpty, recurrence.minutes.isEmpty,
          recurrence.seconds.isEmpty, recurrence.setPositions.isEmpty else {
      throw ClassEventWriteError.nonWeeklyRecurrence
    }
    return try recurrence.weekdays.map { weekday in
      guard case .every(let day) = weekday else { throw ClassEventWriteError.nonWeeklyRecurrence }
      return dayType(day)
    }
  }

  private static func dayType(_ weekday: Locale.Weekday) -> DayType {
    switch weekday {
    case .monday: .mon
    case .tuesday: .tue
    case .wednesday: .wed
    case .thursday: .thu
    case .friday: .fri
    case .saturday: .sat
    case .sunday: .sun
    @unknown default: .mon
    }
  }
}
