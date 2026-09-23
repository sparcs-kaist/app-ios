//
//  TimetableUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain
import WidgetKit

public final class TimetableUseCase: TimetableUseCaseProtocol, @unchecked Sendable {
  // MARK: - Properties
  private let feature: String = "Timetable"
  // MARK: - Dependencies
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol
  private let cache: TimetableCache?
  private let sessionBridgeService: SessionBridgeServiceProtocol?
  private let crashlyticsService: CrashlyticsServiceProtocol?
  
  // MARK: - Initialiser
  public init(
    otlTimetableRepository: OTLTimetableRepositoryProtocol,
    cache: TimetableCache? = nil,
    sessionBridgeService: SessionBridgeServiceProtocol? = nil,
    crashlyticsService: CrashlyticsServiceProtocol? = nil
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.cache = cache
    self.sessionBridgeService = sessionBridgeService
    self.crashlyticsService = crashlyticsService
  }

  // MARK: - Functions
  public func cachedState(semester: Semester?, timetableID: Int?) async -> TimetableCachedState {
    cache?.state(semester: semester, timetableID: timetableID) ?? .init()
  }

  public func getSemesters() async throws -> [Semester] {
    if let cached = cache?.semesters() {
      Task.detached(priority: .background) { [weak self] in _ = try? await self?.refreshSemesters() }
      return cached
    }
    return try await refreshSemesters()
  }

  public func getCurrentSemesters() async throws -> Semester {
    if let cached = cache?.currentSemester() {
      Task.detached(priority: .background) { [weak self] in _ = try? await self?.refreshCurrentSemester() }
      return cached
    }
    return try await refreshCurrentSemester()
  }

  public func refreshSemesters() async throws -> [Semester] {
    let result = try await otlTimetableRepository.getSemesters()
    try Task.checkCancellation()
    cache?.storeSemesters(result)
    return result
  }

  public func refreshCurrentSemester() async throws -> Semester {
    let result = try await otlTimetableRepository.getCurrentSemester()
    try Task.checkCancellation()
    cache?.storeCurrentSemester(result)
    if let table = cache?.timetable(forKey: "\(result.id)-myTable") {
      // Semester refresh does not make the timetable contents any newer.
      cache?.store(table, forKey: "current-myTable")
    }
    return result
  }

  public func getTimetableList(semester: Semester) async throws -> [TimetableSummary] {
    if let cached = cache?.timetableSummaries(semester: semester) {
      Task.detached(priority: .background) { [weak self] in
        _ = try? await self?.refreshTimetableList(semester: semester)
      }
      return cached
    }
    return try await refreshTimetableList(semester: semester)
  }

  public func refreshTimetableList(semester: Semester) async throws -> [TimetableSummary] {
    let result = try await otlTimetableRepository.getTables(year: semester.year, semester: semester.semesterType)
    try Task.checkCancellation()
    cache?.storeTimetableSummaries(result, semester: semester)
    return result
  }

  /// Always refresh the visible timetable; retain offline access to the last successful fetch.
  public func getTable(id: Int) async throws -> Timetable {
    do {
      return try await refreshTable(id: id)
    } catch {
      if Self.canUseCache(after: error), let cached = cache?.timetable(forKey: String(id)) { return cached }
      throw error
    }
  }

  public func refreshTable(id: Int) async throws -> Timetable {
    let result = try await otlTimetableRepository.getTable(timetableID: id)
    try Task.checkCancellation()
    cache?.store(result, forKey: String(id))
    WidgetCenter.shared.reloadAllTimelines()
    return result
  }

  public func saveActivity(timetableID: Int, activityID: Int?, draft: TimetableActivityDraft) async throws -> Timetable {
    guard draft.isValid else { throw TimetableActivityError.invalidTimeOrTitle }
    // Validate against fresh server data, including other devices' changes.
    let current = try await refreshTable(id: timetableID)
    guard !draft.hasConflict(in: current, excluding: activityID) else { throw TimetableActivityError.overlap }
    if let activityID {
      try await otlTimetableRepository.updateActivity(timetableID: timetableID, activityID: activityID, draft: draft)
    } else {
      try await otlTimetableRepository.createActivity(timetableID: timetableID, draft: draft)
    }
    return try await refreshAfterActivityMutation(id: timetableID)
  }

  public func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable {
    do { try await otlTimetableRepository.deleteActivity(timetableID: timetableID, activityID: activityID) }
    catch NetworkError.notFound { /* Already removed by another device or a previous request. */ }
    return try await refreshAfterActivityMutation(id: timetableID)
  }

  private func refreshAfterActivityMutation(id: Int) async throws -> Timetable {
    cache?.invalidate(key: String(id))
    WidgetCenter.shared.reloadAllTimelines()
    do { return try await refreshTable(id: id) }
    catch { throw TimetableActivityError.refreshRequired }
  }

  private static func canUseCache(after error: Error) -> Bool {
    guard let error = error as? NetworkError else { return false }
    switch error {
    case .noConnection, .timeout: return true
    case .serverError(let status): return status >= 500
    default: return false
    }
  }

  /// Fetches the "my table" for a semester, returning cached data immediately while refreshing in background.
  public func getMyTable(semester: Semester) async throws -> Timetable {
    if let cached = cache?.timetable(forKey: "\(semester.id)-myTable") {
      Task.detached(priority: .background) { [weak self] in
        _ = try? await self?.refreshMyTable(semester: semester)
      }
      return cached
    }
    return try await refreshMyTable(semester: semester)
  }

  public func refreshMyTable(semester: Semester) async throws -> Timetable {
    let result = try await otlTimetableRepository.getMyTable(year: semester.year, semester: semester.semesterType)
    try Task.checkCancellation()
    cache?.store(result, forKey: "\(semester.id)-myTable")
    WidgetCenter.shared.reloadAllTimelines()
    Task.detached(priority: .background) { [weak self] in
      guard let self, let current = try? await self.refreshCurrentSemester(), current == semester else { return }
      self.cache?.storeCurrentMyTable(result)
      self.sessionBridgeService?.updateTimetable(result)
    }
    return result
  }

  public func deleteTable(id: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["timetableID": "\(id)"]
    )

    try await execute(context: context) {
      try await self.otlTimetableRepository.deleteTable(timetableID: id)
      self.cache?.invalidate(key: String(id))
      self.cache?.updateTimetableSummary(id: id, title: nil)
    }
  }

  public func renameTable(id: Int, title: String) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["timetableID": "\(id)", "title": title]
    )

    try await execute(context: context) {
      try await self.otlTimetableRepository.renameTable(timetableID: id, title: title)
      self.cache?.updateTimetableSummary(id: id, title: title)
    }
  }

  public func createTable(semester: Semester) async throws -> TableCreation {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "year": "\(semester.year)",
        "semester": "\(semester.semesterType)"
      ]
    )

    return try await execute(context: context) {
      try await self.otlTimetableRepository.createTable(year: semester.year, semester: semester.semesterType)
    }
  }

  /// Copies the semester's "my table" into a brand new table.
  ///
  /// There is no copy endpoint, so the copy is replayed: create an empty table,
  /// then add every lecture and activity of the source table to it. A lecture or
  /// activity the server rejects is skipped and counted rather than aborting the
  /// copy, so a single bad item cannot discard everything else.
  public func duplicateMyTable(semester: Semester, title: String) async throws -> TableDuplication {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "year": "\(semester.year)",
        "semester": "\(semester.semesterType)"
      ]
    )

    return try await execute(context: context) {
      // Copy from the server, not the cache, so the duplicate matches what the
      // user sees on other devices too.
      let source = try await self.otlTimetableRepository
        .getMyTable(year: semester.year, semester: semester.semesterType)
      let creation = try await self.otlTimetableRepository
        .createTable(year: semester.year, semester: semester.semesterType)

      var skippedLectures = 0
      for lecture in source.lectures {
        try Task.checkCancellation()
        do {
          try await self.otlTimetableRepository.addLecture(timetableID: creation.id, lectureID: lecture.id)
        } catch is CancellationError {
          throw CancellationError()
        } catch {
          skippedLectures += 1
          self.crashlyticsService?.record(error: error, context: context)
        }
      }

      var skippedActivities = 0
      for activity in source.activities {
        try Task.checkCancellation()
        do {
          try await self.otlTimetableRepository.createActivity(timetableID: creation.id, draft: activity.draft)
        } catch is CancellationError {
          throw CancellationError()
        } catch {
          skippedActivities += 1
          self.crashlyticsService?.record(error: error, context: context)
        }
      }

      if !title.isEmpty {
        // A failed rename leaves a usable, correctly populated table.
        do { try await self.otlTimetableRepository.renameTable(timetableID: creation.id, title: title) }
        catch { self.crashlyticsService?.record(error: error, context: context) }
      }

      self.cache?.invalidate(key: String(creation.id))
      WidgetCenter.shared.reloadAllTimelines()

      return TableDuplication(
        id: creation.id,
        skippedLectureCount: skippedLectures,
        skippedActivityCount: skippedActivities
      )
    }
  }

  public func addLecture(timetableID: Int, lectureID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "timetableID": "\(timetableID)",
        "lectureID": "\(lectureID)"
      ]
    )

    try await execute(context: context) {
      try await self.otlTimetableRepository.addLecture(timetableID: timetableID, lectureID: lectureID)
      // Invalidate so the updated timetable is fetched fresh on next load.
      self.cache?.invalidate(key: String(timetableID))
    }
  }

  public func deleteLecture(timetableID: Int, lectureID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "timetableID": "\(timetableID)",
        "lectureID": "\(lectureID)"
      ]
    )

    try await execute(context: context) {
      try await self.otlTimetableRepository.deleteLecture(timetableID: timetableID, lectureID: lectureID)
      self.cache?.invalidate(key: String(timetableID))
    }
  }

  // MARK: - Private
  private func execute<T>(
    context: CrashContext,
    _ operation: () async throws -> T
  ) async throws -> T {
    do {
      return try await operation()
    } catch let networkError as NetworkError {
      crashlyticsService?.record(error: networkError, context: context)
      throw networkError
    } catch {
      let mappedError = TimetableUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
