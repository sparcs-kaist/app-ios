//
//  TimetableUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public protocol TimetableUseCaseProtocol: Observable, Sendable {
  func cachedState(semester: Semester?, timetableID: Int?) async -> TimetableCachedState
  /// Refresh methods return server data or throw; they never hide a failure with cached data.
  func refreshSemesters() async throws -> [Semester]
  func refreshCurrentSemester() async throws -> Semester
  func refreshTimetableList(semester: Semester) async throws -> [TimetableSummary]
  func refreshMyTable(semester: Semester) async throws -> Timetable
  func getSemesters() async throws -> [Semester]
  func getCurrentSemesters() async throws -> Semester
  func getTimetableList(semester: Semester) async throws -> [TimetableSummary]
  func getTable(id: Int) async throws -> Timetable
  func getMyTable(semester: Semester) async throws -> Timetable
  func deleteTable(id: Int) async throws
  func renameTable(id: Int, title: String) async throws
  func createTable(semester: Semester) async throws -> TableCreation
  /// Creates a new table for the semester holding a copy of the semester's "my table".
  func duplicateMyTable(semester: Semester, title: String) async throws -> TableDuplication
  func addLecture(timetableID: Int, lectureID: Int) async throws
  func deleteLecture(timetableID: Int, lectureID: Int) async throws
  func saveActivity(timetableID: Int, activityID: Int?, draft: TimetableActivityDraft) async throws -> Timetable
  func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable
  func refreshTable(id: Int) async throws -> Timetable

}

public extension TimetableUseCaseProtocol {
  func cachedState(semester: Semester?, timetableID: Int?) async -> TimetableCachedState { .init() }
  func refreshSemesters() async throws -> [Semester] { try await getSemesters() }
  func refreshCurrentSemester() async throws -> Semester { try await getCurrentSemesters() }
  func refreshTimetableList(semester: Semester) async throws -> [TimetableSummary] {
    try await getTimetableList(semester: semester)
  }
  func refreshMyTable(semester: Semester) async throws -> Timetable { try await getMyTable(semester: semester) }
}
