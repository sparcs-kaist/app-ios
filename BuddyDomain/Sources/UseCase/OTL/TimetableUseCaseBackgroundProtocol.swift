//
//  TimetableUseCaseBackgroundProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation

public protocol TimetableUseCaseBackgroundProtocol {
  func getCurrentMyTable() async -> Timetable
	func getTable(timetableID: Int) async -> Timetable
	func getTableList() async -> [SemesterWithTimetables]
}
