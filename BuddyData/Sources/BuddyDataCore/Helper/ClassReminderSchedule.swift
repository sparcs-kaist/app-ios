//
//  ClassReminderSchedule.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import Foundation
import BuddyDomain

/// Turns a timetable into the weekly slots the feed backend plans class reminders from.
public enum ClassReminderSchedule {
  /// One slot per lecture meeting and per custom block, in weekly order. Lectures are coloured
  /// by course and blocks by id, the same keys the timetable theme colours them by.
  public static func slots(of timetable: Timetable) -> [ClassReminderDeviceRequestDTO.Slot] {
    let lectures = timetable.lectures.flatMap { lecture in
      lecture.classes.enumerated().map { index, lectureClass in
        ClassReminderDeviceRequestDTO.Slot(
          id: "L\(lecture.id):\(index)",
          day: lectureClass.day.rawValue,
          begin: lectureClass.begin,
          end: lectureClass.end,
          title: lecture.name,
          buildingCode: lectureClass.buildingCode.nilIfEmpty,
          buildingName: lectureClass.buildingName,
          room: lectureClass.roomName.nilIfEmpty,
          kind: "lecture",
          colorID: lecture.courseID
        )
      }
    }
    let activities = timetable.activities.map { activity in
      ClassReminderDeviceRequestDTO.Slot(
        id: "A\(activity.id)",
        day: activity.day.rawValue,
        begin: activity.begin,
        end: activity.end,
        title: activity.title,
        buildingCode: nil,
        buildingName: activity.location,
        room: nil,
        kind: "activity",
        colorID: activity.id
      )
    }
    return (lectures + activities).sorted { ($0.day, $0.begin, $0.id) < ($1.day, $1.begin, $1.id) }
  }

  /// OTL's semester numbering: 1 spring, 2 summer, 3 autumn, 4 winter.
  public static func otlNumber(of semester: SemesterType) -> Int {
    switch semester {
    case .spring: 1
    case .summer: 2
    case .autumn: 3
    case .winter: 4
    }
  }
}

private extension String {
  var nilIfEmpty: String? { isEmpty ? nil : self }
}
