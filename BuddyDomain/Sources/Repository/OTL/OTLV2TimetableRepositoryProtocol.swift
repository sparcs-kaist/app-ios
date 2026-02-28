//
//  OTLV2TimetableRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public protocol OTLV2TimetableRepositoryProtocol: Sendable {
  func getTables(year: Int, semester: SemesterType) async throws -> [V2TimetableSummary]
  func getTable(timetableID: Int) async throws -> V2Timetable
  func getMyTable(year: Int, semester: SemesterType) async throws -> V2Timetable
  func deleteTable(timetableID: Int) async throws
  func renameTable(timetableID: Int, title: String) async throws
  func addLecture(timetableID: Int, lectureID: Int) async throws
  func deleteLecture(timetableID: Int, lectureID: Int) async throws
  func getSemesters() async throws -> [Semester]
  func getCurrentSemester() async throws -> Semester
}
