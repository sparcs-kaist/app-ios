//
//  OTLTimetableRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol OTLTimetableRepositoryProtocol: Sendable {
  func getTables(userID: Int, year: Int, semester: SemesterType) async throws -> [Timetable]
  func createTable(userID: Int, year: Int, semester: SemesterType) async throws -> Timetable
  func deleteTable(userID: Int, timetableID: Int) async throws
  func addLecture(userID: Int, timetableID: Int, lectureID: Int) async throws -> Timetable
  func deleteLecture(userID: Int, timetableID: Int, lectureID: Int) async throws -> Timetable
  func getSemesters() async throws -> [Semester]
  func getCurrentSemester() async throws -> Semester
}
