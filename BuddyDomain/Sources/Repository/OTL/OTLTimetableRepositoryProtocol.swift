//
//  OTLTimetableRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public protocol OTLTimetableRepositoryProtocol: Sendable {
  func getTables(year: Int, semester: SemesterType) async throws -> [TimetableSummary]
  func getTable(timetableID: Int) async throws -> Timetable
  func createTable(year: Int, semester: SemesterType) async throws -> TableCreation
  func getMyTable(year: Int, semester: SemesterType) async throws -> Timetable
	func getTableList() async throws -> [SemesterWithTimetables]
  func deleteTable(timetableID: Int) async throws
  func renameTable(timetableID: Int, title: String) async throws
  func getSemesters() async throws -> [Semester]
  func getCurrentSemester() async throws -> Semester

  // Every edit returns the whole timetable as the server holds it afterwards, so
  // callers can show it without fetching it again. It is `nil` only when the edit
  // was applied but the answer couldn't be read.
  @discardableResult
  func addLecture(timetableID: Int, lectureID: Int) async throws -> Timetable?
  @discardableResult
  func deleteLecture(timetableID: Int, lectureID: Int) async throws -> Timetable?
  @discardableResult
  func createActivity(timetableID: Int, draft: TimetableActivityDraft) async throws -> Timetable?
  @discardableResult
  func updateActivity(timetableID: Int, activityID: Int, draft: TimetableActivityDraft) async throws -> Timetable?
  @discardableResult
  func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable?
  /// Applies `changes` all together or not at all.
  @discardableResult
  func updateItems(timetableID: Int, changes: [TimetableItemChange]) async throws -> Timetable?

}
