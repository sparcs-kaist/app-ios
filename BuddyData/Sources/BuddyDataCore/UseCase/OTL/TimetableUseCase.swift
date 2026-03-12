//
//  TimetableUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain

public final class TimetableUseCase: TimetableUseCaseProtocol, @unchecked Sendable {
  // MARK: - Dependencies
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol
  private let cache: TimetableCache?
  private let sessionBridgeService: SessionBridgeServiceProtocol?
  
  // MARK: - Cached State
  private let semesterCache = SemesterCache()

  // MARK: - Initialiser
  public init(
    otlTimetableRepository: OTLTimetableRepositoryProtocol,
    cache: TimetableCache? = nil,
    sessionBridgeService: SessionBridgeServiceProtocol? = nil
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.cache = cache
    self.sessionBridgeService = sessionBridgeService
  }

  // MARK: - Functions
  public func getSemesters() async throws -> [Semester] {
    if let cached = await semesterCache.getSemesters() {
      // Refresh in background
      Task.detached(priority: .background) { [weak self] in
        guard let self else { return }
        if let fresh = try? await self.otlTimetableRepository.getSemesters() {
          await self.semesterCache.setSemesters(fresh)
        }
      }
      return cached
    }
    
    let result = try await otlTimetableRepository.getSemesters()
    await semesterCache.setSemesters(result)
    return result
  }

  public func getCurrentSemesters() async throws -> Semester {
    if let cached = await semesterCache.getCurrentSemester() {
      // Refresh in background
      Task.detached(priority: .background) { [weak self] in
        guard let self else { return }
        if let fresh = try? await self.otlTimetableRepository.getCurrentSemester() {
          await self.semesterCache.setCurrentSemester(fresh)
        }
      }
      return cached
    }
    
    let result = try await otlTimetableRepository.getCurrentSemester()
    await semesterCache.setCurrentSemester(result)
    return result
  }

  public func getTimetableList(semester: Semester) async throws -> [TimetableSummary] {
    return try await otlTimetableRepository
      .getTables(year: semester.year, semester: semester.semesterType)
  }

  /// Fetches a timetable by ID, returning cached data immediately while refreshing in background.
  public func getTable(id: Int) async throws -> Timetable {
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
  public func getMyTable(semester: Semester) async throws -> Timetable {
    let key = "\(semester.year)-\(semester.semesterType.rawValue)-myTable"

    if let cached = cache?.timetable(forKey: key) {
      // Refresh in background and check if we should update watchOS
      Task.detached(priority: .background) { [weak self] in
        guard let self else { return }
        
        // Fetch both fresh timetable and current semester in parallel
        async let freshTimetable = try? await self.otlTimetableRepository
          .getMyTable(year: semester.year, semester: semester.semesterType)
        async let currentSemester = try? await self.otlTimetableRepository.getCurrentSemester()
        
        let (fresh, current) = await (freshTimetable, currentSemester)
        
        if let fresh {
          self.cache?.store(fresh, forKey: key)
          
          // Update watchOS if this is the current semester
          let isCurrentSemester = current?.year == semester.year 
            && current?.semesterType == semester.semesterType
          if isCurrentSemester {
            self.sessionBridgeService?.updateTimetable(fresh)
          }
        }
      }
      return cached
    }

    // No cache - fetch from network
    let result = try await otlTimetableRepository
      .getMyTable(year: semester.year, semester: semester.semesterType)
    cache?.store(result, forKey: key)
    
    // Check if this is the current semester and update watchOS in background
    Task.detached(priority: .background) { [weak self] in
      guard let self else { return }
      if let currentSemester = try? await self.otlTimetableRepository.getCurrentSemester() {
        let isCurrentSemester = currentSemester.year == semester.year 
          && currentSemester.semesterType == semester.semesterType
        if isCurrentSemester {
          self.sessionBridgeService?.updateTimetable(result)
        }
      }
    }
    
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

  public func createTable(semester: Semester) async throws -> TableCreation {
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

// MARK: - SemesterCache Actor
private actor SemesterCache {
  private var semesters: [Semester]?
  private var currentSemester: Semester?
  
  func getSemesters() -> [Semester]? {
    return semesters
  }
  
  func setSemesters(_ value: [Semester]) {
    semesters = value
  }
  
  func getCurrentSemester() -> Semester? {
    return currentSemester
  }
  
  func setCurrentSemester(_ value: Semester) {
    currentSemester = value
  }
}

