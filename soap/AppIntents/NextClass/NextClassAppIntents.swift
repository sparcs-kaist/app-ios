//
//  NextClassAppIntents.swift
//  BuddyiOSAppIntents
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import AppIntents
import BuddyDomain
import BuddyDataCore

struct NextClassAppIntents: AppIntent {
  static var title: LocalizedStringResource { "Get Next Class" }
  static let description: IntentDescription = IntentDescription(
    "Get your next class for this semester.",
    categoryName: "Buddy"
  )
  static let supportedModes: IntentModes = [.background]

  func perform() async throws -> some ProvidesDialog & ReturnsValue<NextClassResult?> & ShowsSnippetView {
    let timetableService = TimetableService()
    try await timetableService.setup()

    guard let timetableUseCase = timetableService.timetableUseCase else {
      return .result(
        value: nil,
        dialog: "Failed to load classes for this semester.",
        view: await NextClassResultView(state: .error)
      )
    }

    let now = Date()
    let currentSemester = await timetableUseCase.currentSemester
    let timetable: Timetable = await timetableUseCase.getMyTable(for: currentSemester?.id ?? "")
    let items: [LectureItem] = timetable.lectureItems(for: now)

    if let nextItem: LectureItem = defaultSelection(items: items) {
      let lectureTitle: String = nextItem.lecture.title.localized()
      let classtime: ClassTime = nextItem.lecture.classTimes[nextItem.index]
      let startDate: Date = dateOnSameDay(minutes: classtime.begin, date: now, calendar: .current) ?? now

      // relative date string
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .full
      let relativeString = formatter.localizedString(for: startDate, relativeTo: now)

      let value = NextClassResult(
        title: lectureTitle,
        location: classtime.classroomName.localized()
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
    let now = Calendar.current.component(.hour, from: Date()) * 60 +
    Calendar.current.component(.minute, from: Date())

    // Look for the next class that starts after `now`
    if let next = items.first(where: { $0.lecture.classTimes[$0.index].begin >= now }) {
      return next
    }

    // No more classes today!
    return nil
  }
}
