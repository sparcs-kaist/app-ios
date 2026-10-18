//
//  ActivityDescriptionScanner.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation

/// Reads the day and the times out of an activity description, such as
/// "월요일 21-22시 SPARCS 정모" or "Study group every Tuesday 7–9pm".
///
/// These follow patterns plain code reads reliably, which the on-device model
/// does not: it misread Korean times, and given today's day to resolve "today"
/// it answered with today whatever day was named. So what this finds overrides
/// the model, which is left the title and the place.
public enum ActivityDescriptionScanner {
  /// The first day the description names, by name or as today or tomorrow.
  public static func day(in text: String, today: DayType) -> DayType? {
    days(in: text, today: today).first
  }

  /// Every day the description names, in the order it names them: by name,
  /// as a run such as 월수금, as today or tomorrow, or as a group such as
  /// "every day", weekdays or 주말.
  public static func days(in text: String, today: DayType) -> [DayType] {
    var found: [(position: Int, days: [DayType])] = []

    for match in matches(of: koreanDay, in: text) {
      if let name = match.groups[1], let day = koreanDays[String(name)] { found.append((match.position, [day])) }
    }
    for match in matches(of: koreanDayRun, in: text) {
      guard let run = match.groups[1] else { continue }
      found.append((match.position, run.compactMap { koreanDays[String($0)] }))
    }
    for match in matches(of: englishDay, in: text) {
      if let name = match.groups[1], let day = englishDays[name.lowercased()] { found.append((match.position, [day])) }
    }
    for match in matches(of: relativeDay, in: text) {
      let isTomorrow = ["내일", "tomorrow"].contains(match.groups[1]?.lowercased() ?? "")
      found.append((match.position, [isTomorrow ? today.next : today]))
    }
    for (expression, days) in dayGroups {
      for match in matches(of: expression, in: text) { found.append((match.position, days)) }
    }

    var days: [DayType] = []
    for day in found.sorted(by: { $0.position < $1.position }).flatMap(\.days) where !days.contains(day) {
      days.append(day)
    }
    return days
  }

  /// The first time or range of times the description gives, in minutes from
  /// midnight. `end` is `nil` when only a start is given.
  public static func times(in text: String) -> (begin: Int, end: Int?)? {
    for match in matches(of: timeRange, in: text) {
      // Groups 1–7 are the start, 8 the word between, and 9–15 the end.
      guard let start = Token(match.groups[1...7]), let end = Token(match.groups[9...15]) else { continue }
      if start.isTimeLike || end.isTimeLike, let resolved = resolve(start, end) {
        return resolved
      }
    }
    for match in matches(of: singleTime, in: text) {
      guard let token = Token(match.groups[1...7]), token.isTimeLike,
            var hour = token.hour24(), hour < 24 else { continue }
      // As for ranges: nobody's weekly activity starts at 3am.
      if token.meridiem == nil, (1...6).contains(hour) { hour += 12 }
      return (hour * 60 + token.minute, nil)
    }
    return nil
  }

  // MARK: - Times

  private struct Token {
    var meridiem: Meridiem?
    var hour: Int
    var minute: Int
    /// Written with a colon, 시 or a meridiem, rather than as a bare number.
    var isTimeLike: Bool

    /// From a time's seven groups: the Korean meridiem, the hour, the minute
    /// after a colon, 시, the minute before 분, 반, and the Latin meridiem.
    init?(_ groups: ArraySlice<Substring?>) {
      let groups = Array(groups)
      guard groups.count == 7, let hourText = groups[1], let hour = Int(hourText) else { return nil }
      let (koreanMeridiem, colonMinute, si, koreanMinute, half, latinMeridiem) =
        (groups[0], groups[2], groups[3], groups[4], groups[5], groups[6])
      self.hour = hour
      self.minute = min(Int(colonMinute ?? koreanMinute ?? "") ?? (half == nil ? 0 : 30), 59)
      if let latinMeridiem {
        self.meridiem = latinMeridiem.lowercased() == "p" ? .pm : .am
      } else if let koreanMeridiem {
        self.meridiem = ["오전", "아침", "새벽"].contains(String(koreanMeridiem)) ? .am : .pm
      }
      self.isTimeLike = meridiem != nil || colonMinute != nil || si != nil
    }

    /// The hour on a 24-hour clock, taking `meridiem` if the token has none of
    /// its own.
    func hour24(assuming assumed: Meridiem? = nil) -> Int? {
      guard (0...24).contains(hour) else { return nil }
      switch meridiem ?? assumed {
      case .pm: return hour < 12 ? hour + 12 : hour
      case .am: return hour == 12 ? 0 : hour
      case nil: return hour
      }
    }
  }

  private enum Meridiem { case am, pm }

  private static func resolve(_ start: Token, _ end: Token) -> (begin: Int, end: Int?)? {
    guard var startHour = start.hour24(), var endHour = end.hour24() else { return nil }

    // "7 to 9pm": a bare start takes the end's afternoon when that keeps it first.
    if start.meridiem == nil, end.meridiem == .pm, startHour < 12, startHour + 12 < endHour {
      startHour += 12
    }
    // "저녁 7-9시": a bare end takes the start's afternoon.
    if end.meridiem == nil, start.meridiem == .pm || startHour >= 12, endHour < 12, endHour + 12 > startHour {
      endHour += 12
    }
    // "1-3시" with no meridiem anywhere: nobody's weekly activity runs from 1am.
    if start.meridiem == nil, end.meridiem == nil, (1...6).contains(startHour), endHour <= 12 {
      startHour += 12
      endHour += 12
    }

    let begin = startHour * 60 + start.minute
    let endMinutes = endHour * 60 + end.minute
    guard startHour < 24, begin < endMinutes, endMinutes <= 24 * 60 else {
      return startHour < 24 ? (begin, nil) : nil
    }
    return (begin, endMinutes)
  }

  /// A time: an optional Korean meridiem, the hour, then minutes after a colon
  /// or as 시 and 분, 시 반, and an optional am or pm. The hour can't follow a
  /// Latin letter or digit, so room numbers such as E11 aren't read as times.
  private static let time = #"(?:(오전|오후|저녁|밤|아침|새벽|낮)\s*)?(?<![A-Za-z0-9])(\d{1,2})(?!\d)(?:\s*:\s*(\d{2})|\s*(시)(?:\s*(\d{1,2})\s*분|\s*(반))?)?(?:\s*([apAP])\.?\s*[mM]\b\.?)?"#

  private static let timeRange = expression(
    time + #"\s*(-|–|—|~|〜|to|until|till|부터)\s*"# + time,
    options: .caseInsensitive
  )
  private static let singleTime = expression(time, options: .caseInsensitive)

  // MARK: - Days

  private static let koreanDay = expression(#"([월화수목금토일])요일"#)
  /// "sat" and "sun" are words too, so their abbreviations count only capitalised.
  private static let englishDay = expression(
    #"\b((?i:monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tues|tue|weds|wed|thurs|thur|thu|fri)|Sat|Sun)s?\b"#
  )
  private static let relativeDay = expression(#"(오늘|내일|(?i:today|tomorrow))"#)
  /// Two or more day initials together, such as 월수금 or 화/목, standing alone
  /// so words such as 일요일 or 금요일 aren't read as runs.
  private static let koreanDayRun = expression(
    #"(?<![가-힣])([월화수목금토일](?:\s*[,/·]?\s*[월화수목금토일])+)(?![가-힣])"#
  )
  private static let dayGroups: [(NSRegularExpression, [DayType])] = [
    (expression(#"매일|날마다|(?i:\bevery\s*day\b|\bdaily\b)"#), DayType.allCases.sorted()),
    (expression(#"평일|주중|(?i:\bweekdays\b|\bevery\s+weekday\b)"#), DayType.weekdays),
    (expression(#"주말|(?i:\bweekends?\b)"#), [.sat, .sun]),
  ]

  // MARK: - Matching

  /// `NSRegularExpression` rather than Swift's `Regex`, which doesn't support
  /// the lookbehind that keeps room numbers from reading as times.
  private static func expression(_ pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression {
    // The patterns are fixed, so one that doesn't compile is a programming error.
    try! NSRegularExpression(pattern: pattern, options: options)
  }

  /// Every match in `text`, in order, with each group's text or `nil` where
  /// the group took no part. Group 0 is the whole match.
  private static func matches(
    of expression: NSRegularExpression,
    in text: String
  ) -> [(position: Int, groups: [Substring?])] {
    expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { result in
      let groups = (0..<result.numberOfRanges).map { index in
        Range(result.range(at: index), in: text).map { text[$0] }
      }
      return (result.range.location, groups)
    }
  }

  private static let koreanDays: [String: DayType] = [
    "월": .mon, "화": .tue, "수": .wed, "목": .thu, "금": .fri, "토": .sat, "일": .sun,
  ]

  private static let englishDays: [String: DayType] = [
    "monday": .mon, "mon": .mon,
    "tuesday": .tue, "tues": .tue, "tue": .tue,
    "wednesday": .wed, "weds": .wed, "wed": .wed,
    "thursday": .thu, "thurs": .thu, "thur": .thu, "thu": .thu,
    "friday": .fri, "fri": .fri,
    "saturday": .sat, "sat": .sat,
    "sunday": .sun, "sun": .sun,
  ]
}

private extension DayType {
  var next: DayType {
    switch self {
    case .mon: .tue
    case .tue: .wed
    case .wed: .thu
    case .thu: .fri
    case .fri: .sat
    case .sat: .sun
    case .sun: .mon
    }
  }
}
