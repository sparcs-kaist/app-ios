//
//  V2LectureClass.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct V2LectureClass: Hashable, Sendable, Codable {
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

  public func statusString(at now: Date) -> String {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.hour, .minute], from: now)
    let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

    if currentMinutes < begin {
      let diff = begin - currentMinutes
      return String(localized: "in \(formatMinutes(diff))", bundle: .module)
    } else if currentMinutes >= end {
      let diff = currentMinutes - end
      return String(localized: "\(formatMinutes(diff)) ago", bundle: .module)
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
    let h = minutes / 60
    let m = minutes % 60
    switch (h, m) {
    case (0, let m): return String(localized: "\(m)m", bundle: .module)
    case (let h, 0): return String(localized: "\(h)h", bundle: .module)
    default:         return String(localized: "\(h)h \(m)m", bundle: .module)
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
