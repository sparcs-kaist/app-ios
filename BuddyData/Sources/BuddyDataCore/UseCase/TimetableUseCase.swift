//
//  TimetableUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 17/09/2025.
//

import Foundation
import Observation
import BuddyDomain

@Observable
public final class TimetableUseCase: TimetableUseCaseProtocol {
  // MARK: - Properties
  private var store: [Semester.ID: [Timetable]] = [:]
  public var semesters: [Semester] = []

  /// Prevent overlapping fetches per semester when the user switches quickly.
  private var fetchingSemesters = Set<Semester.ID>()

  public var selectedSemesterID: Semester.ID? = nil {
    didSet {
      guard let selectedSemesterID else { return }
      // Always default-select My Table of the chosen semester
      selectedTimetableID = "\(selectedSemesterID)-myTable"

      // Refresh tables for the newly selected semester
      Task { [weak self] in
        await self?.refreshTablesForSelectedSemester()
      }
    }
  }

  public var selectedTimetableID: Timetable.ID? = nil

  // MARK: - Dependencies
  private let userUseCase: UserUseCaseProtocol
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol
  private let sessionBridgeService: SessionBridgeServiceProtocol

  // MARK: - Initialiser
  public init(
    userUseCase: UserUseCaseProtocol,
    otlTimetableRepository: OTLTimetableRepositoryProtocol,
    sessionBridgeService: SessionBridgeServiceProtocol
  ) {
    self.userUseCase = userUseCase
    self.otlTimetableRepository = otlTimetableRepository
    self.sessionBridgeService = sessionBridgeService
  }

  // MARK: - Computed
  public var selectedSemester: Semester? {
    guard let id = selectedSemesterID else { return nil }
    return semesters.first(where: { $0.id == id })
  }

  public var selectedTimetable: Timetable? {
    guard let sid = selectedSemesterID,
          let tid = selectedTimetableID else { return nil }
    return store[sid]?.first(where: { $0.id == tid })
  }

  public var timetableIDsForSelectedSemester: [String] {
    guard let sid = selectedSemesterID else { return [] }
    return store[sid]?.map(\.id) ?? []
  }

  /// Human-friendly display name for the selected timetable.
  /// - "My Table" for the local user table
  /// - "Table N" for the Nth server table (1-based index)
  /// - "Unknown" as a safe fallback
  public var selectedTimetableDisplayName: String {
    guard let selectedTimetableID = selectedTimetableID else { return String(localized: "Unknown") }

    if selectedTimetableID.hasSuffix("-myTable") {
      return String(localized: "My Table")
    }

    if let index = timetableIDsForSelectedSemester.firstIndex(of: selectedTimetableID) {
      return String(localized: "Table \(index)")
    } else {
      return String(localized: "Unknown")
    }
  }

  public var isEditable: Bool {
    if let selectedTimetable = selectedTimetable {
      return selectedTimetable.id.contains("myTable") ? false : true
    }

    return false
  }

  // MARK: - API
  public func load() async throws {
    // Avoid re-loading if already populated
    guard store.isEmpty || semesters.isEmpty else { return }

    async let fetchSemesters = otlTimetableRepository.getSemesters()
    async let fetchCurrentSemester = otlTimetableRepository.getCurrentSemester()

    let (fetchedSemesters, fetchedCurrentSemester) = try await (fetchSemesters, fetchCurrentSemester)

    // Persist semesters
    semesters = fetchedSemesters

    // Seed each semester with a local "My Table" derived from user lectures
    let user: OTLUser? = await userUseCase.otlUser
    store = Dictionary(
      uniqueKeysWithValues: semesters.map { semester in
        (semester.id, [makeMyTable(for: semester, user: user)])
      }
    )

    // Select the current semester if it exists; otherwise last
    if let matched = semesters.first(where: {
      $0.year == fetchedCurrentSemester.year && $0.semesterType == fetchedCurrentSemester.semesterType
    }) {
      selectedSemesterID = matched.id
    } else {
      selectedSemesterID = semesters.last?.id
    }

    // Ensure a selected timetable for the chosen semester
    if let sid = selectedSemesterID {
      selectedTimetableID = "\(sid)-myTable"
    }

    // Fetch remote tables for the selected semester and merge
    await refreshTablesForSelectedSemester()

    // update watchOS data

    // select my table of current semester in the future
    if let timetable: Timetable = store[fetchedCurrentSemester.id]?.first {
      sessionBridgeService.updateTimetable(timetable)
    }
  }

  public func createTable() async throws {
    guard
      let user: OTLUser = await userUseCase.otlUser,
      let selectedSemester
    else { return }

    // Create on server
    let newTable: Timetable = try await otlTimetableRepository.createTable(
      userID: user.id,
      year: selectedSemester.year,
      semester: selectedSemester.semesterType
    )

    // Insert into local store for the semester (dedup & keep myTable first)
    let sid = selectedSemester.id
    let existing = store[sid] ?? []
    let merged = mergeKeepingMyTableFirst(existing: existing, incoming: [newTable])
    store[sid] = merged

    // Select the newly created table
    selectedTimetableID = newTable.id
  }

  public func deleteTable() async throws {
    guard isEditable,
          let sid = selectedSemesterID,
          let tid = selectedTimetableID,
          let user = await userUseCase.otlUser,
          let timetableID = Int(tid)
    else { return }

    // Delete on server
    try await otlTimetableRepository.deleteTable(userID: user.id, timetableID: timetableID)

    // Update local store
    var tables = store[sid] ?? []
    tables.removeAll { $0.id == tid }
    store[sid] = tables

    // Select the last timetable if available
    selectedTimetableID = tables.last?.id
  }

  public func addLecture(lecture: Lecture) async throws {
    guard isEditable,
          let sid = selectedSemesterID,
          let tid = selectedTimetableID,
          let user = await userUseCase.otlUser,
          let timetableID = Int(tid)
    else { return }

    let updatedTable: Timetable = try await otlTimetableRepository.addLecture(
      userID: user.id,
      timetableID: timetableID,
      lectureID: lecture.id
    )

    // Patch local store
    var tables = store[sid] ?? []
    if let idx = tables.firstIndex(where: { $0.id == tid }) {
      tables[idx] = updatedTable
    } else {
      tables.append(updatedTable)
    }

    // Keep -myTable (if any) at the front
    store[sid] = mergeKeepingMyTableFirst(existing: tables, incoming: [])

    // Ensure selection still points to the edited table
    selectedTimetableID = updatedTable.id
  }

  public func deleteLecture(lecture: Lecture) async throws {
    guard isEditable,
          let sid = selectedSemesterID,
          let tid = selectedTimetableID,
          let user = await userUseCase.otlUser,
          let timetableID = Int(tid)
    else { return }

    let updatedTable: Timetable = try await otlTimetableRepository.deleteLecture(
      userID: user.id,
      timetableID: timetableID,
      lectureID: lecture.id
    )

    // Patch local store
    var tables = store[sid] ?? []
    if let idx = tables.firstIndex(where: { $0.id == tid }) {
      tables[idx] = updatedTable
    } else {
      tables.append(updatedTable)
    }

    // Keep -myTable (if any) at the front
    store[sid] = mergeKeepingMyTableFirst(existing: tables, incoming: [])

    // Ensure selection still points to the edited table
    selectedTimetableID = updatedTable.id
  }

  // MARK: - Helpers

  /// Refresh tables for `selectedSemesterID`, seeding My Table if needed and merging server tables (deduped).
  @MainActor
  private func refreshTablesForSelectedSemester() async {
    guard
      let sid = selectedSemesterID,
      let semester = semesters.first(where: { $0.id == sid })
    else { return }

    // Seed myTable if missing
    let otlUser: OTLUser? = await userUseCase.otlUser
    seedMyTableIfNeeded(semester: semester, user: otlUser)

    // Avoid concurrent fetches for the same semester
    guard !fetchingSemesters.contains(sid) else { return }
    fetchingSemesters.insert(sid)
    defer { fetchingSemesters.remove(sid) }

    guard let user = otlUser else { return }

    do {
      let fetched = try await otlTimetableRepository.getTables(
        userID: user.id,
        year: semester.year,
        semester: semester.semesterType
      )

      let existing = store[sid] ?? []
      let merged = mergeKeepingMyTableFirst(existing: existing, incoming: fetched)
      store[sid] = merged

      // If current selection disappeared, fall back to myTable
      if let tid = selectedTimetableID, !merged.contains(where: { $0.id == tid }) {
        selectedTimetableID = "\(sid)-myTable"
      }
    } catch {
    }
  }

  /// Ensures there is a `-myTable` entry for the given semester,
  /// filled with the user's lectures for that semester.
  @MainActor
  private func seedMyTableIfNeeded(semester: Semester, user: OTLUser?) {
    let sid = semester.id
    if let existing = store[sid], existing.contains(where: { $0.id.hasSuffix("-myTable") }) {
      return
    }
    let my = makeMyTable(for: semester, user: user)
    var tables = store[sid] ?? []
    // Pin myTable to the front, then append the rest
    tables.removeAll(where: { $0.id.hasSuffix("-myTable") })
    tables.insert(my, at: 0)
    store[sid] = tables
  }

  /// Creates the local "My Table" for a semester using user's lectures.
  private func makeMyTable(for semester: Semester, user: OTLUser?) -> Timetable {
    let lectures = user?.myTimetableLectures.filter {
      $0.year == semester.year && $0.semester == semester.semesterType
    } ?? []
    return Timetable(id: "\(semester.id)-myTable", lectures: lectures)
  }

  /// Merge helper that:
  /// - keeps order of existing tables
  /// - appends any new ones not present (by id)
  /// - keeps `-myTable` as the first element if present
  @MainActor
  private func mergeKeepingMyTableFirst(existing: [Timetable], incoming: [Timetable]) -> [Timetable] {
    var seen = Set(existing.map { $0.id })
    var result = existing
    for t in incoming where !seen.contains(t.id) {
      result.append(t)
      seen.insert(t.id)
    }

    // Ensure -myTable is at index 0 if present
    if let myIdx = result.firstIndex(where: { $0.id.hasSuffix("-myTable") }), myIdx != 0 {
      var copy = result
      let my = copy.remove(at: myIdx)
      copy.insert(my, at: 0)
      return copy
    }
    return result
  }
}
