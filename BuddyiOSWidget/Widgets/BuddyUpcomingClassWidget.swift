//
//  BuddyiOSWidget.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyDataCore
import BuddyUpcomingClassWidgetUI

struct UpcomingClassProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> LectureEntry {
    LectureEntry(
      date: Date(),
      lecture: V2Lecture.mock,
      lectureClass: V2Lecture.mock.classes[0],
      startDate: dateOnSameDay(
        minutes: V2Lecture.mock.classes[0].begin,
        date: Date(),
        calendar: .current
      )!,
      signInRequired: false,
      backgroundColor: V2Lecture.mock.backgroundColor,
      relevance: .init(score: 50)
    )
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> LectureEntry {
    LectureEntry(
      date: Date(),
      lecture: V2Lecture.mock,
      lectureClass: V2Lecture.mock.classes[0],
      startDate: dateOnSameDay(
        minutes: V2Lecture.mock.classes[0].begin,
        date: Date(),
        calendar: .current
      )!,
      signInRequired: false,
      backgroundColor: V2Lecture.mock.backgroundColor,
      relevance: .init(score: 50)
    )
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LectureEntry> {
    let now = Date()
    let calendar = Calendar.current

    let timetableService = TimetableService()
    try? await timetableService.setup()

    guard let timetableUseCase = timetableService.timetableUseCase else {
      // return error
      let entry = LectureEntry(
        date: now,
        lecture: nil,
        lectureClass: nil,
        startDate: nil,
        signInRequired: true,
        backgroundColor: .black,
        relevance: .init(score: 20)
      )
      return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*30)))
    }

    let timetable: V2Timetable = await timetableUseCase.getCurrentMyTable()
//    let timetable: Timetable = await timetableUseCase.getMyTable(for: "2024-Autumn")
    let todayLectures: [V2LectureItem] = timetable.lectureItems(for: now)

    var entries: [LectureEntry] = []
    if todayLectures.isEmpty {
      let entry = LectureEntry(
        date: now,
        lecture: nil,
        lectureClass: nil,
        startDate: Date(),
        signInRequired: false,
        backgroundColor: .black,
        relevance: .init(score: 10)
      )
      entries.append(entry)
    } else {
      for item in todayLectures {
        let ct = item.lectureClass
        guard let start = dateOnSameDay(minutes: ct.begin, date: now, calendar: calendar)
        else { continue }

        // Upcoming Lectures (30 minutes before the start)
        let pre = max(now, start.addingTimeInterval(-30*60))
        if pre <= start {
          entries
            .append(
              LectureEntry(
                date: pre,
                lecture: item.lecture,
                lectureClass: ct,
                startDate: start,
                signInRequired: false,
                backgroundColor: item.lecture.backgroundColor,
                relevance: .init(score: 100)
              )
            )
        }

        // Start-of-class entry
        if start >= now {
          entries
            .append(
              LectureEntry(
                date: start,
                lecture: item.lecture,
                lectureClass: ct,
                startDate: start,
                signInRequired: false,
                backgroundColor: item.lecture.backgroundColor,
                relevance: .init(score: 80)
              )
            )
        }
      }

      if entries.isEmpty {
        let entry = LectureEntry(
          date: now,
          lecture: nil,
          lectureClass: nil,
          startDate: nil,
          signInRequired: false,
          backgroundColor: .black,
          relevance: .init(score: 20)
        )
        entries.append(entry)
      }
    }

    entries.sort { $0.date < $1.date }

    return Timeline(entries: entries, policy: .atEnd)
  }
}

struct BuddyUpcomingClassWidgetEntryView: View {
  @Environment(\.widgetFamily) private var familiy
  var entry: UpcomingClassProvider.Entry

  var body: some View {
    Group {
      switch familiy {
      case .accessoryRectangular:
        UpcomingClassRectangleWidgetView(entry: entry)
      case .accessoryInline:
        UpcomingClassInlineWidgetView(entry: entry)
      case .accessoryCircular:
        UpcomingClassCircularWidgetView(entry: entry)
      case .systemSmall:
        UpcomingClassSmallWidgetView(entry: entry)
      default:
        Text("Not supported")
      }
    }
  }
}

struct BuddyUpcomingClassWidget: Widget {
  let kind: String = "BuddyUpcomingClassWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: UpcomingClassProvider()) { entry in
      BuddyUpcomingClassWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .supportedFamilies(
      [.accessoryRectangular, .accessoryInline, .accessoryCircular, .systemSmall]
    )
    .configurationDisplayName("Upcoming Class")
    .description("Keep track of your classes.")
  }
}

#Preview(as: .systemSmall) {
  BuddyUpcomingClassWidget()
} timeline: {
  let lectures = Array(V2Lecture.mockList.suffix(5))
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
