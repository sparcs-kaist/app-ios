//
//  V2TimetableUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import Observation
import BuddyDomain

@Observable
public final class V2TimetableUseCase: V2TimetableUseCaseProtocol, @unchecked Sendable {
  // MARK: - Dependencies
  private let otlTimetableRepository: OTLV2TimetableRepositoryProtocol
  private let sessionBirdgeService: SessionBridgeServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlTimetableRepository: OTLV2TimetableRepositoryProtocol,
    sessionBirdgeService: SessionBridgeServiceProtocol?
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.sessionBirdgeService = sessionBirdgeService
  }

  // MARK: - Functions
  public func getSemesters() async throws -> [Semester] {
    return try await otlTimetableRepository.getSemesters()
  }

  public func getCurrentSemesters() async throws -> Semester {
    return try await otlTimetableRepository.getCurrentSemester()
  }

  public func getTimetableList(semester: Semester) async throws -> [V2TimetableSummary] {
    return try await otlTimetableRepository
      .getTables(year: semester.year, semester: semester.semesterType)
  }

  public func getTable(id: Int) async throws -> V2Timetable {
    return try await otlTimetableRepository.getTable(timetableID: id)
  }

  public func getMyTable(semester: Semester) async throws -> V2Timetable {
    return try await otlTimetableRepository
      .getMyTable(year: semester.year, semester: semester.semesterType)
  }

  public func deleteTable(id: Int) async throws {
    try await otlTimetableRepository.deleteTable(timetableID: id)
  }

  public func renameTable(id: Int, title: String) async throws {
    try await otlTimetableRepository.renameTable(timetableID: id, title: title)
  }

  public func createTable(semester: Semester) async throws -> V2TableCreation {
    try await otlTimetableRepository.createTable(year: semester.year, semester: semester.semesterType)
  }
}
