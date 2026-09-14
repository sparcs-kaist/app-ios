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
  func addLecture(timetableID: Int, lectureID: Int) async throws
  func deleteLecture(timetableID: Int, lectureID: Int) async throws
  func getSemesters() async throws -> [Semester]
  func getCurrentSemester() async throws -> Semester
  func getActivities(timetableID: Int) async throws -> [TimetableActivity]
  func createActivity(timetableID: Int, draft: TimetableActivityDraft) async throws
  func updateActivity(timetableID: Int, activityID: Int, draft: TimetableActivityDraft) async throws
  func deleteActivity(timetableID: Int, activityID: Int) async throws

}
