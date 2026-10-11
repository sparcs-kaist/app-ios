//
//  CachedTimetableUseCase.swift
//  BuddyData
//

import Foundation
import BuddyDomain

/// Reads timetables from the shared cache only, never the network.
///
/// The app refreshes the cache before it asks for a reindex, so Spotlight can be
/// rebuilt without repeating those requests or refreshing tokens again.
public struct CachedTimetableUseCase: TimetableUseCaseBackgroundProtocol {
  private let cache: TimetableCache

  public init(cache: TimetableCache) {
    self.cache = cache
  }

  public func getCurrentMyTable() async -> Timetable {
    cache.currentMyTable() ?? Timetable(id: "-myTable", lectures: [])
  }

  public func getMyTable(year: Int, semester: SemesterType) async -> Timetable {
    let key = "\(year)-\(semester.rawValue)-myTable"
    return cache.timetable(forKey: key) ?? Timetable(id: key, lectures: [])
  }

  public func getTable(timetableID: Int) async -> Timetable {
    cache.timetable(forKey: String(timetableID)) ?? Timetable(id: String(timetableID), lectures: [])
  }

  /// Built from the app's per-semester summaries, which reflect renames and
  /// deletions immediately, falling back to the widgets' list.
  public func getTableList() async -> [SemesterWithTimetables] {
    let fromSummaries = (cache.semesters() ?? []).compactMap { semester -> SemesterWithTimetables? in
      guard let summaries = cache.timetableSummaries(semester: semester) else { return nil }
      return SemesterWithTimetables(
        year: semester.year,
        semester: semester.semesterType,
        timetables: summaries.map { TimetableHeader(id: $0.id, name: $0.title) }
      )
    }
    return fromSummaries.isEmpty ? (cache.timetableList() ?? []) : fromSummaries
  }

  public func getCurrentSemester() async -> Semester? {
    cache.currentSemester()
  }
}
