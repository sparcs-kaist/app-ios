//
//  BuddyWatchWidget.swift
//  BuddyWatchWidget
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyUpcomingClassWidgetUI

struct UpcomingClassProvider: TimelineProvider {
  private let suite = "group.org.sparcs.soap"
  private let key = "timetableData"

  func placeholder(in context: Context) -> LectureEntry {
    LectureEntry(
      date: Date(),
      lecture: Lecture.mock,
      lectureClass: Lecture.mock.classes[0],
      startDate: dateOnSameDay(
        minutes: Lecture.mock.classes[0].begin,
        date: Date(),
        calendar: .current
      )!,
      signInRequired: false,
      backgroundColor: Lecture.mock.backgroundColor,
      relevance: .init(score: 50)
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (LectureEntry) -> ()) {
    completion(placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let now = Date()

    let ud = UserDefaults(suiteName: suite)
    let data = ud?.data(forKey: key) ?? Data()
    guard
      !data.isEmpty,
      let timetable: Timetable = try? JSONDecoder().decode(Timetable.self, from: data)
    else {
      // failed to decode timetable
      let entry = LectureEntry(
        date: now,
        lecture: nil,
        lectureClass: nil,
        startDate: nil,
        signInRequired: true,
        backgroundColor: .black,
        relevance: .init(score: 10)
      )
      completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*30))))
      return
    }

    // The same shared builder as the iOS widget: lectures and custom
    // activities, ongoing events with their end boundaries, coloured by the
    // theme synced from the phone.
    let entries = TimetableEventTimeline.entries(
      for: timetable,
      now: now,
      theme: TimetableThemeStore().selectedTheme
    )
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct BuddyUpcomingClassWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  var entry: LectureEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryRectangular:
        UpcomingClassRectangleWidgetView(entry: entry)
      case .accessoryInline:
        UpcomingClassInlineWidgetView(entry: entry)
      case .accessoryCircular:
        UpcomingClassCircularWidgetView(entry: entry)
      case .accessoryCorner:
        UpcomingClassCornerWidgetView(entry: entry)
      default:
        Text("Not supported")
      }
    }
    .containerBackground(entry.backgroundColor.gradient, for: .widget)
  }
}

struct BuddyUpcomingClassWidget: Widget {
  let kind: String = "BuddyWatchWidgetUpcomingClass"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: UpcomingClassProvider()) { entry in
      BuddyUpcomingClassWidgetEntryView(entry: entry)
    }
    .supportedFamilies(
      [.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner]
    )
    .configurationDisplayName("Upcoming Class")
    .description("Keep track of your classes.")
  }
}

#Preview(as: .accessoryRectangular) {
  BuddyUpcomingClassWidget()
} timeline: {
  let lectures = Array(Lecture.mockList.suffix(5))
  LectureEntry(
    date: Date(),
    lecture: lectures[0],
    lectureClass: lectures[0].classes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[0].classes.first!.begin,
      date: Date(),
      calendar: .current
    ),
    signInRequired: false,
    backgroundColor: lectures[0].backgroundColor,
    relevance: .init(score: 50)
  )
  LectureEntry(
    date: Date().addingTimeInterval(60*10),
    lecture: lectures[1],
    lectureClass: lectures[1].classes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[1].classes.first!.begin,
      date: Date(),
      calendar: .current
    ),
    signInRequired: false,
    backgroundColor: lectures[1].backgroundColor,
    relevance: .init(score: 50)
  )
  LectureEntry(
    date: Date().addingTimeInterval(60*20),
    lecture: lectures[2],
    lectureClass: lectures[2].classes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[2].classes.first!.begin,
      date: Date(),
      calendar: .current
    ),
    signInRequired: false,
    backgroundColor: lectures[1].backgroundColor,
    relevance: .init(score: 50)
  )
  LectureEntry(
    date: Date().addingTimeInterval(60*20),
    lecture: lectures[3],
    lectureClass: lectures[3].classes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[3].classes.first!.begin,
      date: Date(),
      calendar: .current
    ),
    signInRequired: false,
    backgroundColor: lectures[3].backgroundColor,
    relevance: .init(score: 50)
  )
  LectureEntry(
    date: Date().addingTimeInterval(60*20),
    lecture: nil,
    lectureClass: nil,
    startDate: nil,
    signInRequired: false,
    backgroundColor: .black,
    relevance: .init(score: 50)
  )
  LectureEntry(
    date: Date().addingTimeInterval(60*20),
    lecture: nil,
    lectureClass: nil,
    startDate: nil,
    signInRequired: true,
    backgroundColor: .black,
    relevance: .init(score: 50)
  )
}
