//
//  NextClassAppIntents.swift
//  BuddyiOSAppIntents
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import AppIntents
import BuddyDomain
import BuddyDataCore
import BuddyIntents

struct NextClassAppIntents: AppIntent {
  static var title: LocalizedStringResource { "Get Next Class" }
  static let description: IntentDescription = IntentDescription(
    "Get your next class for this semester.",
    categoryName: "Buddy"
  )
  static let supportedModes: IntentModes = [.background]

  func perform() async throws -> some ProvidesDialog & ReturnsValue<NextClassResult?> & ShowsSnippetView {
    // The timetable selected in Buddy, or the current semester's My Table.
    guard let active = await ActiveTimetableResolver.app()?.resolve() else {
      return .result(
        value: nil,
        dialog: "Failed to load classes for this semester.",
        view: await NextClassResultView(state: .error)
      )
    }

    let now = Date()
    let items: [LectureItem] = Self.lectureItems(in: active.timetable, on: now)

    if let nextItem: LectureItem = defaultSelection(items: items) {
      let lectureTitle: String = nextItem.lecture.name
      let classtime: LectureClass = nextItem.lectureClass
      let startDate: Date = dateOnSameDay(minutes: classtime.begin, date: now, calendar: .kaist) ?? now

      // relative date string
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .full
      let relativeString = formatter.localizedString(for: startDate, relativeTo: now)

      let value = NextClassResult(
        title: lectureTitle,
        location: "\(classtime.buildingCode) \(classtime.roomName)"
      )

      return .result(
        value: value,
        dialog: "Your next class is \"\(lectureTitle)\", starts \(relativeString).",
        view: await NextClassResultView(state: .success(item: nextItem))
      )
    }

    return .result(
      value: nil,
      dialog: "There are no more classes today.",
      view: await NextClassResultView(state: .success(item: nil))
    )
  }

  private func defaultSelection(items: [LectureItem]) -> LectureItem? {
    let components = Calendar.kaist.dateComponents([.hour, .minute], from: Date())
    let now = (components.hour ?? 0) * 60 + (components.minute ?? 0)

    // Look for the next class that starts after `now`
    if let next = items.first(where: { $0.lectureClass.begin >= now }) {
      return next
    }

    // No more classes today!
    return nil
  }

  /// Today's classes in KAIST time, wherever the device is.
  private static func lectureItems(in timetable: Timetable, on date: Date) -> [LectureItem] {
    let today = DayType.from(date: date, calendar: .kaist)
    return timetable.lectures
      .flatMap { lecture in
        lecture.classes.filter { $0.day == today }.map { LectureItem(lecture: lecture, lectureClass: $0) }
      }
      .sorted { $0.lectureClass.begin < $1.lectureClass.begin }
  }
}
