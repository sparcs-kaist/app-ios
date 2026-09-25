//
//  LectureViewOption.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI

/// The four ways of presenting the timetable on the watch, mirroring the
/// Apple Calendar app's view options.
enum LectureViewOption: String, CaseIterable, Identifiable {
  case upNext
  case list
  case day
  case week

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .upNext: "Up Next"
    case .list: "List"
    case .day: "Day"
    case .week: "Week"
    }
  }

  var systemImage: String {
    switch self {
    case .upNext: "clock"
    case .list: "list.bullet"
    case .day: "calendar.day.timeline.left"
    case .week: "calendar"
    }
  }
}
