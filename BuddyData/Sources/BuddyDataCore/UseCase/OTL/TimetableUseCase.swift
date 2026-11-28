//
//  TimetableUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain
import WidgetKit
import Synchronization

public final class TimetableUseCase: TimetableUseCaseProtocol, @unchecked Sendable {
  // MARK: - Properties
  private let feature: String = "Timetable"
  // MARK: - Dependencies
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol
  private let cache: TimetableCache?
  private let sessionBridgeService: SessionBridgeServiceProtocol?
  private let crashlyticsService: CrashlyticsServiceProtocol?
  private let timetableIndexingService: TimetableIndexingServiceProtocol?
  /// Per table, how many edits have finished, and the table the latest one left. A fetch
  /// that started before an edit finished may hold the table from before it, so it must not
  /// be saved over the edit's result.
  private let edits = Mutex<[Int: (version: Int, table: Timetable?)]>([:])
  
  // MARK: - Initialiser
  public init(
    otlTimetableRepository: OTLTimetableRepositoryProtocol,
    cache: TimetableCache? = nil,
    sessionBridgeService: SessionBridgeServiceProtocol? = nil,
    crashlyticsService: CrashlyticsServiceProtocol? = nil,
    timetableIndexingService: TimetableIndexingServiceProtocol? = nil
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.cache = cache
    self.sessionBridgeService = sessionBridgeService
    self.crashlyticsService = crashlyticsService
    self.timetableIndexingService = timetableIndexingService
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
    let version = editVersion(of: id)
    let result = try await otlTimetableRepository.getTable(timetableID: id)
    try Task.checkCancellation()
    // An edit finished while this was in flight: its answer is at least as new as this one.
    if editVersion(of: id) != version {
      if let edited = edits.withLock({ $0[id]?.table }) { return edited }
      return result
    }
    keep(result, id: id)
    return result
  }

  private func editVersion(of id: Int) -> Int {
    edits.withLock { $0[id]?.version ?? 0 }
  }

  /// Marks an edit of `id` as finished, leaving `table` (or nothing known, when `nil`).
  private func recordEdit(of id: Int, leaving table: Timetable?) {
    edits.withLock { $0[id] = (version: ($0[id]?.version ?? 0) + 1, table: table) }
  }

  /// Saves a fresh copy of a table and passes it on to the widgets, Siri and the watch.
  private func keep(_ table: Timetable, id: Int) {
    cache?.store(table, forKey: String(id))
    WidgetCenter.shared.reloadAllTimelines()
    timetableIndexingService?.scheduleReindex()
    pushToWatchIfSelected(table, semester: nil, timetableID: id)
  }

  /// Runs an edit and keeps the timetable the server answers with, as the web does,
  /// rather than fetching it again.
  private func applyEdit(id: Int, _ edit: () async throws -> Timetable?) async throws -> Timetable {
    guard let updated = try await edit() else { return try await refreshAfterEdit(id: id) }
    recordEdit(of: id, leaving: updated)
    keep(updated, id: id)
    return updated
  }

  /// The watch mirrors whichever timetable is selected in the Timetable tab,
  /// so every fresh fetch of that table — a selection change, a lecture or
  /// activity edit, a background refresh — pushes it. With no saved selection
  /// yet, the current semester's My Table is pushed as before.
  private func pushToWatchIfSelected(_ table: Timetable, semester: Semester?, timetableID: Int?) {
    guard let sessionBridgeService else { return }
    if let saved = TimetableSelectionStore().selection {
      let isSelected = if let timetableID {
        saved.timetableID == timetableID
      } else if let semester {
        saved.timetableID == nil && saved.matches(semester)
      } else {
        false
      }
      if isSelected { sessionBridgeService.updateTimetable(table) }
    } else if timetableID == nil, let semester, cache?.currentSemester() == semester {
      sessionBridgeService.updateTimetable(table)
    }
  }

  public func saveActivity(timetableID: Int, activityID: Int?, draft: TimetableActivityDraft) async throws -> Timetable {
    guard draft.isValid else { throw TimetableActivityError.invalidTimeOrTitle }
    // Validate against fresh server data, including other devices' changes.
    let current = try await refreshTable(id: timetableID)
    guard !draft.hasConflict(in: current, excluding: activityID) else { throw TimetableActivityError.overlap }
    return try await applyEdit(id: timetableID) {
      if let activityID {
        try await otlTimetableRepository.updateActivity(timetableID: timetableID, activityID: activityID, draft: draft)
      } else {
        try await otlTimetableRepository.createActivity(timetableID: timetableID, draft: draft)
      }
    }
  }

  public func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable {
    do {
      return try await applyEdit(id: timetableID) {
        try await otlTimetableRepository.deleteActivity(timetableID: timetableID, activityID: activityID)
      }
    } catch NetworkError.notFound {
      // Already removed by another device or a previous request.
      return try await refreshAfterEdit(id: timetableID)
    }
  }

  /// Fetches a table whose edit went through without a readable answer.
  private func refreshAfterEdit(id: Int) async throws -> Timetable {
    // Fetches that began before the edit can't tell their table from the edit's.
    recordEdit(of: id, leaving: nil)
    cache?.invalidate(key: String(id))
    WidgetCenter.shared.reloadAllTimelines()
    timetableIndexingService?.scheduleReindex()
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
    timetableIndexingService?.scheduleReindex()
    pushToWatchIfSelected(result, semester: semester, timetableID: nil)
    Task.detached(priority: .background) { [weak self] in
      guard let self, let current = try? await self.refreshCurrentSemester(), current == semester else { return }
      self.cache?.storeCurrentMyTable(result)
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
      self.timetableIndexingService?.scheduleReindex()
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
      self.timetableIndexingService?.scheduleReindex()
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
      self.timetableIndexingService?.scheduleReindex()

      return TableDuplication(
        id: creation.id,
        skippedLectureCount: skippedLectures,
        skippedActivityCount: skippedActivities
      )
    }
  }

  @discardableResult
  public func addLecture(timetableID: Int, lectureID: Int) async throws -> Timetable {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "timetableID": "\(timetableID)",
        "lectureID": "\(lectureID)"
      ]
    )

    return try await execute(context: context) {
      try await self.applyEdit(id: timetableID) {
        try await self.otlTimetableRepository.addLecture(timetableID: timetableID, lectureID: lectureID)
      }
    }
  }

  @discardableResult
  public func deleteLecture(timetableID: Int, lectureID: Int) async throws -> Timetable {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "timetableID": "\(timetableID)",
        "lectureID": "\(lectureID)"
      ]
    )

    return try await execute(context: context) {
      try await self.applyEdit(id: timetableID) {
        try await self.otlTimetableRepository.deleteLecture(timetableID: timetableID, lectureID: lectureID)
      }
    }
  }

  @discardableResult
  public func applyChanges(timetableID: Int, changes: [TimetableItemChange]) async throws -> Timetable {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "timetableID": "\(timetableID)",
        "changeCount": "\(changes.count)"
      ]
    )

    return try await execute(context: context) {
      try await self.applyEdit(id: timetableID) {
        try await self.otlTimetableRepository.updateItems(timetableID: timetableID, changes: changes)
      }
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
