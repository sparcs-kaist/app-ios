//
//  TimetableUseCaseBackgroundAdapter.swift
//  BuddyData
//

import Foundation
import BuddyDomain

/// Lets code written against `TimetableUseCaseBackgroundProtocol` use the app's
/// own timetable use case.
///
/// Inside the app, requests then share the app's authenticated networking and
/// its single coalesced token refresh. A separate `TimetableService` refreshes on
/// its own, and two refreshes racing over a rotated refresh token can sign the
/// user out.
public struct TimetableUseCaseBackgroundAdapter: TimetableUseCaseBackgroundProtocol {
  private let useCase: TimetableUseCaseProtocol

  public init(_ useCase: TimetableUseCaseProtocol) {
    self.useCase = useCase
  }

  public func getCurrentSemester() async -> Semester? {
    try? await useCase.getCurrentSemesters()
  }

  public func getCurrentMyTable() async -> Timetable {
    guard let semester = await getCurrentSemester() else { return Timetable(id: "-myTable", lectures: []) }
    return await getMyTable(year: semester.year, semester: semester.semesterType)
  }

  public func getMyTable(year: Int, semester: SemesterType) async -> Timetable {
    let empty = Timetable(id: "\(year)-\(semester.rawValue)-myTable", lectures: [])
    guard let match = await self.semester(year: year, type: semester) else { return empty }
    return (try? await useCase.getMyTable(semester: match)) ?? empty
  }

  public func getTable(timetableID: Int) async -> Timetable {
    (try? await useCase.getTable(id: timetableID)) ?? Timetable(id: String(timetableID), lectures: [])
  }

  /// The current semester's tables only: the app fetches lists per semester, and
  /// callers only need the current one.
  public func getTableList() async -> [SemesterWithTimetables] {
    guard let semester = await getCurrentSemester(),
          let summaries = try? await useCase.getTimetableList(semester: semester) else { return [] }
    return [SemesterWithTimetables(
      year: semester.year,
      semester: semester.semesterType,
      timetables: summaries.map { TimetableHeader(id: $0.id, name: $0.title) }
    )]
  }

  private func semester(year: Int, type: SemesterType) async -> Semester? {
    if let current = await getCurrentSemester(), current.year == year, current.semesterType == type {
      return current
    }
    return try? await useCase.getSemesters().first { $0.year == year && $0.semesterType == type }
  }
}
