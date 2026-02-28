//
//  V2TimetableUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public protocol V2TimetableUseCaseProtocol: Observable, Sendable {
  func getSemesters() async throws -> [Semester]
  func getCurrentSemesters() async throws -> Semester
  func getTimetableList(semester: Semester) async throws -> [V2TimetableSummary]
  func deleteTable(id: Int) async throws
  func renameTable(id: Int, title: String) async throws
}
