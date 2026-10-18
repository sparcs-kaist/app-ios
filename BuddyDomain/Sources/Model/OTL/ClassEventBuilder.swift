import Foundation

/// Turns the weekly timetable and the semester's academic dates into dated
/// calendar events, always in KAIST time (`Calendar.kaist`).
public enum ClassEventBuilder {
  /// One weekly event per lecture class time and per activity time, from the first
  /// occurrence on or after the semester's start until the semester ends.
  ///
  /// - Parameter timetableID: The user table's ID, or nil for My Table.
  public static func events(
    for timetable: Timetable,
    timetableID: Int?,
    semester: Semester,
    calendar: Calendar = .kaist
  ) -> [ClassEvent] {
    let recurrence = Calendar.RecurrenceRule.weekly(calendar: calendar, end: .afterDate(semester.endDate))

    let lectures: [ClassEvent] = timetable.lectures.flatMap { lecture in
      lecture.classes.compactMap { lectureClass -> ClassEvent? in
        guard let start = firstOccurrence(of: lectureClass.day, minute: lectureClass.begin,
                                          onOrAfter: semester.beginDate, calendar: calendar),
              lectureClass.end > lectureClass.begin else { return nil }
        return ClassEvent(
          id: ClassEvent.lectureID(lecture, lectureClass),
          title: lecture.name,
          startDate: start,
          endDate: start.addingTimeInterval(TimeInterval(lectureClass.duration * 60)),
          recurrence: recurrence,
          location: location(of: lectureClass),
          note: note(for: lecture)
        )
      }
    }

    let activities: [ClassEvent] = timetable.activities.flatMap(\.slots).compactMap { slot in
      let activity = slot.activity
      guard slot.duration > 0,
            let start = firstOccurrence(of: slot.day, minute: slot.begin,
                                        onOrAfter: semester.beginDate, calendar: calendar) else { return nil }
      let location = activity.location.trimmingCharacters(in: .whitespacesAndNewlines)
      return ClassEvent(
        id: ClassEvent.activityID(timetableID: timetableID, activityID: activity.id, timeIndex: slot.timeIndex),
        title: activity.title,
        startDate: start,
        endDate: start.addingTimeInterval(TimeInterval(slot.duration * 60)),
        recurrence: recurrence,
        location: location.isEmpty ? nil : location
      )
    }

    return (lectures + activities).sorted { $0.startDate < $1.startDate }
  }

  /// Every dated meeting of every weekly series through the semester.
  ///
  /// Siri answers "what do I have tomorrow?" by searching indexed events by date
  /// and doesn't expand recurrence rules, so each meeting is indexed on its own.
  public static func occurrences(
    for timetable: Timetable,
    timetableID: Int?,
    semester: Semester,
    calendar: Calendar = .kaist
  ) -> [ClassEvent] {
    let dayFormat = Date.ISO8601FormatStyle(dateSeparator: .dash, timeZone: calendar.timeZone).year().month().day()
    return events(for: timetable, timetableID: timetableID, semester: semester, calendar: calendar)
      .flatMap { series in
        (0...).lazy
          .compactMap { week in calendar.date(byAdding: .weekOfYear, value: week, to: series.startDate) }
          .prefix { $0 <= semester.endDate }
          .map { start in
            ClassEvent(
              id: ClassEvent.occurrenceID(seriesID: series.id, day: start.formatted(dayFormat)),
              title: series.title,
              startDate: start,
              endDate: start.addingTimeInterval(series.endDate.timeIntervalSince(series.startDate)),
              location: series.location,
              note: series.note
            )
          }
      }
      .sorted { $0.startDate < $1.startDate }
  }

  /// All-day events for the semester's start and end and every academic date the
  /// server provides.
  public static func academicEvents(for semester: Semester, calendar: Calendar = .kaist) -> [ClassEvent] {
    let dates = semester.eventDate
    let fields: [(field: String, title: String, start: Date?, end: Date?)] = [
      ("begin", String(localized: "Semester Begins", bundle: .module), semester.beginDate, nil),
      ("registration", String(localized: "Course Registration", bundle: .module),
       dates.registrationPeriodStartDate, dates.registrationPeriodEndDate),
      ("addDropEnd", String(localized: "Add/Drop Period Ends", bundle: .module), dates.addDropPeriodEndDate, nil),
      ("dropDeadline", String(localized: "Course Drop Deadline", bundle: .module), dates.dropDeadlineDate, nil),
      ("evaluationDeadline", String(localized: "Course Evaluation Deadline", bundle: .module),
       dates.evaluationDeadlineDate, nil),
      ("end", String(localized: "Semester Ends", bundle: .module), semester.endDate, nil),
      ("gradePosting", String(localized: "Grades Posted", bundle: .module), dates.gradePostingDate, nil),
    ]

    return fields.compactMap { field in
      guard let start = field.start else { return nil }
      let firstDay = calendar.startOfDay(for: start)
      let lastDay = calendar.startOfDay(for: max(field.end ?? start, start))
      guard let end = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return nil }
      return ClassEvent(
        id: ClassEvent.academicID(semester: semester, field: field.field),
        title: field.title,
        startDate: firstDay,
        endDate: end,
        isAllDay: true
      )
    }
  }

  /// The first `day` at `minute` past midnight on or after `date`'s day.
  public static func firstOccurrence(
    of day: DayType,
    minute: Int,
    onOrAfter date: Date,
    calendar: Calendar = .kaist
  ) -> Date? {
    let startOfDay = calendar.startOfDay(for: date)
    let offset = (weekday(of: day) - calendar.component(.weekday, from: startOfDay) + 7) % 7
    guard let dayStart = calendar.date(byAdding: .day, value: offset, to: startOfDay) else { return nil }
    return calendar.date(byAdding: .minute, value: minute, to: dayStart)
  }

  /// A lecture's weekly meetings on one line, e.g. "Mon/Wed 09:00–10:30 · E11 304".
  /// Meetings at different times or rooms are listed separately, joined by "; ".
  public static func weeklySchedule(of lecture: Lecture) -> String {
    func time(_ minutes: Int) -> String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }
    var groups: [(key: String, days: [DayType])] = []
    for lectureClass in lecture.classes.sorted(by: { ($0.day, $0.begin) < ($1.day, $1.begin) }) {
      let key = "\(time(lectureClass.begin))–\(time(lectureClass.end)) · \(lectureClass.location)"
      if let index = groups.firstIndex(where: { $0.key == key }) {
        groups[index].days.append(lectureClass.day)
      } else {
        groups.append((key, [lectureClass.day]))
      }
    }
    return groups
      .map { group in "\(group.days.map(\.stringValue).joined(separator: "/")) \(group.key)" }
      .joined(separator: "; ")
  }

  /// Foundation's weekday (Sunday = 1) for a `DayType` (Monday = 0 … Sunday = 6).
  public static func weekday(of day: DayType) -> Int {
    (day.rawValue + 1) % 7 + 1
  }

  /// The inverse of `weekday(of:)`.
  public static func day(ofWeekday weekday: Int) -> DayType? {
    DayType(rawValue: (weekday + 5) % 7)
  }

  // MARK: - Search terms
  //
  // Not localised: Spotlight matches these whatever language the question is
  // in, and KAIST students use both, including colloquial terms like 종강 that
  // never appear in an event's title.

  /// Search terms for an event, by its kind; academic dates by their field.
  /// A lecture's code and professors are already searchable through its note.
  public static func keywords(forEventID id: String) -> [String] {
    switch ClassEvent.kind(of: id) {
    case .lecture: lectureKeywords
    case .activity: activityKeywords
    case .academic: academicKeywords[String(id.split(separator: ":").last ?? "")] ?? []
    case nil: []
    }
  }

  /// Terms students use for a lecture in either language.
  public static let lectureKeywords = ["class", "lecture", "course", "수업", "강의", "과목"]
  private static let activityKeywords = ["activity", "schedule", "활동", "일정"]
  private static let academicKeywords: [String: [String]] = [
    "begin": ["first day of classes", "start of semester", "개강", "학기 시작", "개강일"],
    "registration": ["course registration", "enrolment", "수강신청"],
    "addDropEnd": ["add/drop", "course change", "수강변경", "수강정정", "정정 기간"],
    "dropDeadline": ["drop deadline", "withdraw", "수강취소", "수강철회", "드랍"],
    "evaluationDeadline": ["course evaluation", "lecture evaluation", "강의평가"],
    "end": ["last day of classes", "end of semester", "종강", "학기 종료", "학기 끝", "종강일"],
    "gradePosting": ["grades", "results", "성적 공개", "성적 발표", "성적"],
  ]

  private static func location(of lectureClass: LectureClass) -> String {
    lectureClass.buildingName.isEmpty
      ? lectureClass.location
      : "\(lectureClass.location), \(lectureClass.buildingName)"
  }

  private static func note(for lecture: Lecture) -> String {
    var parts = [lecture.code]
    let professors = lecture.professors.map(\.name).joined(separator: ", ")
    if !professors.isEmpty { parts.append(professors) }
    parts.append(String(localized: "\(lecture.credit) credits", bundle: .module))
    return parts.joined(separator: " · ")
  }
}
