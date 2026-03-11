//
//  V2TimetableUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain

public final class V2TimetableUseCase: V2TimetableUseCaseProtocol, @unchecked Sendable {
  // MARK: - Dependencies
  private let otlTimetableRepository: OTLV2TimetableRepositoryProtocol
  private let cache: TimetableCache?

  // MARK: - Initialiser
  public init(
    otlTimetableRepository: OTLV2TimetableRepositoryProtocol,
    cache: TimetableCache? = nil
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.cache = cache
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

  /// Fetches a timetable by ID, returning cached data immediately while refreshing in background.
  public func getTable(id: Int) async throws -> V2Timetable {
    let key = String(id)

    if let cached = cache?.timetable(forKey: key) {
      // Refresh cache in the background without blocking the caller.
      Task.detached(priority: .background) { [weak self] in
        guard let self else { return }
        if let fresh = try? await self.otlTimetableRepository.getTable(timetableID: id) {
          self.cache?.store(fresh, forKey: key)
        }
      }
      return cached
    }

    // No cache – fetch from network and store.
    let result = try await otlTimetableRepository.getTable(timetableID: id)
    cache?.store(result, forKey: key)
    return result
  }

  /// Fetches the "my table" for a semester, returning cached data immediately while refreshing in background.
  public func getMyTable(semester: Semester) async throws -> V2Timetable {
    let key = "\(semester.year)-\(semester.semesterType.rawValue)-myTable"

    if let cached = cache?.timetable(forKey: key) {
      Task.detached(priority: .background) { [weak self] in
        guard let self else { return }
        if let fresh = try? await self.otlTimetableRepository
          .getMyTable(year: semester.year, semester: semester.semesterType) {
          self.cache?.store(fresh, forKey: key)
        }
      }
      return cached
    }

    let result = try await otlTimetableRepository
      .getMyTable(year: semester.year, semester: semester.semesterType)
    cache?.store(result, forKey: key)
    return result
  }

  public func deleteTable(id: Int) async throws {
    try await otlTimetableRepository.deleteTable(timetableID: id)
    cache?.invalidate(key: String(id))
  }

  public func renameTable(id: Int, title: String) async throws {
    try await otlTimetableRepository.renameTable(timetableID: id, title: title)
    // Invalidate so the renamed table is fetched fresh next time.
    cache?.invalidate(key: String(id))
  }

  public func createTable(semester: Semester) async throws -> V2TableCreation {
    try await otlTimetableRepository.createTable(year: semester.year, semester: semester.semesterType)
  }

  public func addLecture(timetableID: Int, lectureID: Int) async throws {
    try await otlTimetableRepository.addLecture(timetableID: timetableID, lectureID: lectureID)
    // Invalidate so the updated timetable is fetched fresh on next load.
    cache?.invalidate(key: String(timetableID))
  }

  public func deleteLecture(timetableID: Int, lectureID: Int) async throws {
    try await otlTimetableRepository.deleteLecture(timetableID: timetableID, lectureID: lectureID)
    cache?.invalidate(key: String(timetableID))
  }
}
