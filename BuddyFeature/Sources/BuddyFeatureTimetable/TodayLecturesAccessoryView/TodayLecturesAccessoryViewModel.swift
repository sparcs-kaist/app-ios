//
//  TodayLecturesAccessoryViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 09/03/2026.
//

import Observation
import Foundation
import BuddyDomain
import Factory

@MainActor
@Observable
public final class TodayLecturesAccessoryViewModel {
  @ObservationIgnored @Injected(
    \.v2TimetableUseCase
  ) private var v2TimetableUseCase: TimetableUseCaseProtocol?

  public var semesters: [Semester] = []
  public var selectedSemester: Semester? = nil
  public var timetable: Timetable? = nil
  public var isLoading: Bool = true

  public init() { }

  public func setup() async {
    guard let timetableUseCase = v2TimetableUseCase else { return }

    isLoading = true
    defer { isLoading = false }

    do {
      semesters = try await timetableUseCase.getSemesters()
      selectedSemester = try await timetableUseCase.getCurrentSemesters()
//      selectedSemester = semesters.first(where: { $0.year == 2024} )

      if let selectedSemester {
        timetable = try await timetableUseCase.getMyTable(semester: selectedSemester)
      } else {
        timetable = nil
      }
    } catch {
      semesters = []
      selectedSemester = nil
      timetable = nil
    }
  }

  public var hasSemester: Bool {
    !(semesters.isEmpty || selectedSemester == nil)
  }

  public var isEmptySemester: Bool {
    timetable?.lectures.isEmpty ?? true
  }

  public var todayLectures: [LectureItem] {
    timetable?.lectureItems(for: Date()) ?? []
  }

  public var nextLecture: LectureItem? {
    nextLecture(for: Date())
  }

  public func nextLecture(for date: Date) -> LectureItem? {
    let timedLectures: [(item: LectureItem, start: Date, end: Date)] = todayLectures.map { item in
      let start = dateForMinutes(item.lectureClass.begin, on: date)
      let end = dateForMinutes(item.lectureClass.end, on: date)
      return (item: item, start: start, end: end)
    }
    .sorted { $0.start < $1.start }

    if let upcoming = timedLectures.first(where: { date < $0.start }) {
      return upcoming.item
    }

    return nil
  }

  public func dateForMinutes(_ minutes: Int, on date: Date) -> Date {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? date
  }
}
