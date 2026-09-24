//
//  LectureClass.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct LectureClass: Hashable, Sendable, Codable {
  public let day: DayType
  public let begin: Int
  public let end: Int
  public let buildingCode: String
  public let buildingName: String
  public let roomName: String

  public var duration: Int {
    end - begin
  }

  public var description: String {
    func formatTime(_ minutes: Int) -> String {
      let hours = minutes / 60
      let mins = minutes % 60
      return String(format: "%02d:%02d", hours, mins)
    }
    return "\(formatTime(begin))-\(formatTime(end))"
  }
	
	public var location: String {
		"\(buildingCode) \(roomName)"
	}

  public func statusString(at now: Date) -> String {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.hour, .minute], from: now)
    let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

    // Distance within the Mon–Sun week the timetable shows, so yesterday's
    // class reads "1d 2h ago" and Friday's "in 2d", not a bare time-of-day
    // difference.
    let dayOffset = (day.rawValue - DayType.from(date: now, calendar: calendar).rawValue) * 1440
    let beginDelta = dayOffset + begin - currentMinutes
    let endDelta = dayOffset + end - currentMinutes

    if beginDelta > 0 {
      return String(localized: "in \(formatMinutes(beginDelta))", bundle: .module)
    } else if endDelta <= 0 {
      return String(localized: "\(formatMinutes(-endDelta)) ago", bundle: .module)
    } else {
      return String(localized: "on going", bundle: .module)
    }
  }

  public func begin(at now: Date) -> Date {
    let calendar = Calendar.current

    let hour = begin / 60
    let minute = begin % 60

    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
  }

  private func formatMinutes(_ minutes: Int) -> String {
    let d = minutes / 1440
    let h = (minutes % 1440) / 60
    let m = minutes % 60
    switch (d, h, m) {
    case (0, 0, let m):     return String(localized: "\(m)m", bundle: .module)
    case (0, let h, 0):     return String(localized: "\(h)h", bundle: .module)
    case (0, let h, let m): return String(localized: "\(h)h \(m)m", bundle: .module)
    // Once days are involved, minutes are noise.
    case (let d, 0, _):     return String(localized: "\(d)d", bundle: .module)
    case (let d, let h, _): return String(localized: "\(d)d \(h)h", bundle: .module)
    }
  }

  public init(
    day: DayType,
    begin: Int,
    end: Int,
    buildingCode: String,
    buildingName: String,
    roomName: String
  ) {
    self.day = day
    self.begin = begin
    self.end = end
    self.buildingCode = buildingCode
    self.buildingName = buildingName
    self.roomName = roomName
  }
}
