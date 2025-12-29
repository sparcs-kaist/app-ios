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
import BuddyDataMocks
import BuddyUpcomingClassWidgetUI

struct UpcomingClassProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> LectureEntry {
    LectureEntry(
      date: Date(),
      lecture: Lecture.mock,
      classtime: Lecture.mock.classTimes[0],
      startDate: dateOnSameDay(
        minutes: Lecture.mock.classTimes[0].begin,
        date: Date(),
        calendar: .current
      )!,
      signInRequired: false,
      backgroundColor: Lecture.mock.backgroundColor,
      relevance: .init(score: 50)
    )
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> LectureEntry {
    LectureEntry(
      date: Date(),
      lecture: Lecture.mock,
      classtime: Lecture.mock.classTimes[0],
      startDate: dateOnSameDay(
        minutes: Lecture.mock.classTimes[0].begin,
        date: Date(),
        calendar: .current
      )!,
      signInRequired: false,
      backgroundColor: Lecture.mock.backgroundColor,
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
        classtime: nil,
        startDate: nil,
        signInRequired: true,
        backgroundColor: .black,
        relevance: .init(score: 20)
      )
      return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*30)))
    }

    let currentSemester = await timetableUseCase.currentSemester
    let timetable: Timetable = await timetableUseCase.getMyTable(for: currentSemester?.id ?? "")
//    let timetable: Timetable = await timetableUseCase.getMyTable(for: "2024-Autumn")
    let todayLectures: [LectureItem] = timetable.lectureItems(for: now)

    var entries: [LectureEntry] = []
    if todayLectures.isEmpty {
      let entry = LectureEntry(
        date: now,
        lecture: nil,
        classtime: nil,
        startDate: Date(),
        signInRequired: false,
        backgroundColor: .black,
        relevance: .init(score: 10)
      )
      entries.append(entry)
    } else {
      for item in todayLectures {
        let ct = item.lecture.classTimes[item.index]
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
                classtime: ct,
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
                classtime: ct,
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
          classtime: nil,
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
  let lectures = Array(Lecture.mockList.suffix(5))
  LectureEntry(
    date: Date(),
    lecture: lectures[0],
    classtime: lectures[0].classTimes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[0].classTimes.first!.begin,
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
    classtime: lectures[1].classTimes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[1].classTimes.first!.begin,
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
    classtime: lectures[2].classTimes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[2].classTimes.first!.begin,
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
    classtime: lectures[3].classTimes.first!,
    startDate: dateOnSameDay(
      minutes: lectures[3].classTimes.first!.begin,
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
    classtime: nil,
    startDate: nil,
    signInRequired: false,
    backgroundColor: .black,
    relevance: .init(score: 50)
  )
  LectureEntry(
    date: Date().addingTimeInterval(60*20),
    lecture: nil,
    classtime: nil,
    startDate: nil,
    signInRequired: true,
    backgroundColor: .black,
    relevance: .init(score: 50)
  )
}
