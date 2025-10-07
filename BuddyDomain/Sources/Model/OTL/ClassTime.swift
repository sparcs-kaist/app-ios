//
//  ClassTime.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct ClassTime: Sendable, Codable {
  public let buildingCode: String
  public let classroomName: LocalizedString
  public let classroomNameShort: LocalizedString
  public let roomName: String
  public let day: DayType
  public let begin: Int
  public let end: Int

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
      return "in \(formatMinutes(diff))"
    } else if currentMinutes >= end {
      let diff = currentMinutes - end
      return "ended \(formatMinutes(diff)) ago"
    } else {
      return "now"
    }
  }

  private func formatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    switch (h, m) {
    case (0, let m): return "\(m)m"
    case (let h, 0): return "\(h)h"
    default:         return "\(h)h \(m)m"
    }
  }

  public init(
    buildingCode: String,
    classroomName: LocalizedString,
    classroomNameShort: LocalizedString,
    roomName: String,
    day: DayType,
    begin: Int,
    end: Int
  ) {
    self.buildingCode = buildingCode
    self.classroomName = classroomName
    self.classroomNameShort = classroomNameShort
    self.roomName = roomName
    self.day = day
    self.begin = begin
    self.end = end
  }
}
