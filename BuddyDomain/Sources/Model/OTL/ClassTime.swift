//
//  ClassTime.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct ClassTime: Sendable {
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

  public var statusString: String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.hour, .minute], from: now)
    let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

    if currentMinutes < begin {
      // Class hasn't started yet
      let diff = begin - currentMinutes
      return "in \(formatMinutes(diff))"
    } else if currentMinutes >= end {
      // Class already ended
      let diff = currentMinutes - end
      return "ended \(formatMinutes(diff)) ago"
    } else {
      // Class is ongoing
      return "now"
    }
  }

  private func formatMinutes(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours > 0 {
      return "\(hours)h \(mins)m"
    } else {
      return "\(mins)m"
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
