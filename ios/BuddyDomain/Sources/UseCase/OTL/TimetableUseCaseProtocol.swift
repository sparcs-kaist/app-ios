//
//  TimetableUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public protocol TimetableUseCaseProtocol: Observable, Sendable {
  func getSemesters() async throws -> [Semester]
  func getCurrentSemesters() async throws -> Semester
  func getTimetableList(semester: Semester) async throws -> [TimetableSummary]
  func getTable(id: Int) async throws -> Timetable
  func getMyTable(semester: Semester) async throws -> Timetable
  func deleteTable(id: Int) async throws
  func renameTable(id: Int, title: String) async throws
  func createTable(semester: Semester) async throws -> TableCreation
  func addLecture(timetableID: Int, lectureID: Int) async throws
  func deleteLecture(timetableID: Int, lectureID: Int) async throws
}
