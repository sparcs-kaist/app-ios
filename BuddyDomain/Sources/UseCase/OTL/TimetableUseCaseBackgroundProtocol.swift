//
//  TimetableUseCaseBackgroundProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation

public protocol TimetableUseCaseBackgroundProtocol: Sendable {
  func getCurrentMyTable() async -> Timetable
  /// My Table for any semester, falling back to the cache when offline.
  func getMyTable(year: Int, semester: SemesterType) async -> Timetable
	func getTable(timetableID: Int) async -> Timetable
	func getTableList() async -> [SemesterWithTimetables]
	func getCurrentSemester() async -> Semester?
}
