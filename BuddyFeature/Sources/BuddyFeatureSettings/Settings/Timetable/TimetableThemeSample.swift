//
//  TimetableThemeSample.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/09/2026.
//

import Foundation
import BuddyDomain

/// A small stand-in timetable so the theme preview shows several colours at once
/// without depending on whether the user's own table is loaded.
enum TimetableThemeSample {
  static let beginTime = 540  // 9:00
  static let endTime = 900    // 15:00

  static var timetable: Timetable {
    Timetable(
      id: "theme-preview",
      lectures: courses.enumerated().map { index, course in
        lecture(index: index, name: course.name, classes: course.classes)
      },
      activities: [
        TimetableActivity(
          id: 6,
          title: String(localized: "Club", bundle: .module),
          location: "N1",
          day: .fri,
          begin: 780,
          end: 870
        )
      ]
    )
  }

  private static var courses: [(name: String, classes: [(day: DayType, begin: Int, end: Int)])] {
    [
      (String(localized: "Calculus", bundle: .module), [(.mon, 540, 630), (.wed, 540, 630)]),
      (String(localized: "Physics", bundle: .module), [(.tue, 660, 780), (.thu, 660, 780)]),
      (String(localized: "Programming", bundle: .module), [(.mon, 780, 870), (.wed, 780, 870)]),
      (String(localized: "Design", bundle: .module), [(.tue, 810, 900)]),
      (String(localized: "Seminar", bundle: .module), [(.fri, 570, 660)]),
      (String(localized: "Lab", bundle: .module), [(.thu, 810, 900)])
    ]
  }

  private static func lecture(
    index: Int,
    name: String,
    classes: [(day: DayType, begin: Int, end: Int)]
  ) -> Lecture {
    // Sequential course IDs so consecutive theme colours are all visible.
    Lecture(
      id: 900_000 + index,
      courseID: index,
      section: "A",
      name: name,
      subtitle: "",
      code: "",
      department: Department(id: 0, name: ""),
      type: .etc,
      capacity: 0,
      enrolledCount: 0,
      credit: 3,
      creditAU: 0,
      grade: 0,
      load: 0,
      speech: 0,
      isEnglish: true,
      professors: [],
      classes: classes.map {
        LectureClass(
          day: $0.day,
          begin: $0.begin,
          end: $0.end,
          buildingCode: "E11",
          buildingName: "",
          roomName: "\(101 + index)"
        )
      },
      exams: [],
      classDuration: 90,
      expDuration: 0
    )
  }
}
