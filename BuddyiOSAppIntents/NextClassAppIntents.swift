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
  static var description: IntentDescription = IntentDescription(
    "Get your next class for this semester.",
    categoryName: "Buddy"
  )
  static var supportedModes: IntentModes = [.background]

  func perform() async throws -> some ProvidesDialog & ReturnsValue<NextClassResult?> {
    let timetableService = TimetableService()
    try await timetableService.setup()

    guard let timetableUseCase = timetableService.timetableUseCase else {
      return .result(value: nil, dialog: "Failed to load classes for this semester")
    }

    let now = Date()
    let timetable: Timetable = await timetableUseCase.getMyTable(for: "2024-Autumn")
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

      return .result(value: value, dialog: "Your next class is \"\(lectureTitle)\", starts in \(relativeString).")
    }

    return .result(
      value: nil,
      dialog: "There are no more classes today."
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

struct NextClassResult: TransientAppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Next Class"
  )

  @Property
  var title: String

  @Property
  var location: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title),
      subtitle: LocalizedStringResource(stringLiteral: location),
      image: .init(systemName: "calendar.badge.clock")
    )
  }

  init() {

  }

  init(title: String, location: String) {
    self.title = title
    self.location = location
  }
}
