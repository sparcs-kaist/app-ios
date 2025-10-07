//
//  BuddyWatchWidget.swift
//  BuddyWatchWidget
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyDataMocks

struct LectureEntry: TimelineEntry {
  let date: Date
  let lecture: Lecture?
  let classtime: ClassTime?
  let startDate: Date?
  let signInRequired: Bool
  let backgroundColor: Color
  let relevance: TimelineEntryRelevance
}

struct Provider: TimelineProvider {
  private let suite = "group.org.sparcs.soap"
  private let key = "timetableData"

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

  func getSnapshot(in context: Context, completion: @escaping (LectureEntry) -> ()) {
    completion(placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let now = Date()
    let calendar = Calendar.current

    let ud = UserDefaults(suiteName: suite)
    let data = ud?.data(forKey: key) ?? Data()
    guard
      !data.isEmpty,
      let timetable = try? JSONDecoder().decode(Timetable.self, from: data)
    else {
      // failed to decode timetable
      let entry = LectureEntry(
        date: now,
        lecture: nil,
        classtime: nil,
        startDate: nil,
        signInRequired: true,
        backgroundColor: .black,
        relevance: .init(score: 10)
      )
      completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60*30))))
      return
    }

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
        if pre >= now {
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

    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct UpcomingClassRectangleWidgetView: View {
  var entry: LectureEntry

  var body: some View {
    if let lecture = entry.lecture, let ct = entry.classtime {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .center) {
          Circle()
            .frame(width: 12, height: 12)
            .padding(.top, 2)

          Text(ct.description)
            .fontDesign(.rounded)
            .lineLimit(1)
            .fontWeight(.semibold)
        }
        .foregroundStyle(entry.backgroundColor)

        Group {
          Text(lecture.title.localized())
            .fontWeight(.semibold)
          HStack {
            Text(ct.classroomNameShort.localized())
              .foregroundStyle(.secondary)
            Spacer()
          }
        }
        .minimumScaleFactor(0.8)
      }
    } else if entry.signInRequired {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .center) {
          Circle()
            .frame(width: 12, height: 12)
            .padding(.top, 2)

          Text("Sign in Required")
            .minimumScaleFactor(0.9)
            .lineLimit(1)
            .fontWeight(.semibold)
        }
        .foregroundStyle(.accent)

        HStack {
          Text("Open Buddy on your iPhone to continue")
            .multilineTextAlignment(.leading)
          Spacer()
        }
        .minimumScaleFactor(0.8)
      }
    } else {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .center) {
          Circle()
            .frame(width: 12, height: 12)
            .padding(.top, 2)

          Text("No more classes")
            .minimumScaleFactor(0.9)
            .lineLimit(1)
            .fontWeight(.semibold)
        }
        .foregroundStyle(.accent)

        HStack {
          Text("Enjoy your day")
            .multilineTextAlignment(.leading)
          Spacer()
        }
        .minimumScaleFactor(0.8)
      }
      Spacer()
    }
  }
}

struct UpcomingClassInlineWidgetView: View {
  var entry: LectureEntry

  var body: some View {
    if let lecture = entry.lecture, let start = entry.startDate {
      Text("\(start, style: .time) • \(lecture.title.localized())")
    } else if entry.signInRequired {
      Text("Sign in Required")
    } else {
      Text("No more classes")
    }
  }
}





struct BuddyWatchWidgetEntryView: View {
  @Environment(\.widgetFamily) private var familiy
  var entry: LectureEntry

  var body: some View {
    Group {
      switch familiy {
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

struct BuddyWatchWidget: Widget {
  let kind: String = "BuddyWatchWidgetUpcomingClass"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      BuddyWatchWidgetEntryView(entry: entry)
    }
    .supportedFamilies([.accessoryRectangular, .accessoryInline])
    .configurationDisplayName("Upcoming Class")
    .description("Check out the next class.")
  }
}

#Preview(as: .accessoryRectangular) {
  BuddyWatchWidget()
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
