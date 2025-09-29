//
//  TimetableUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 17/09/2025.
//

import Foundation
import Observation

@MainActor
protocol TimetableUseCaseProtocol: Observable {
  var semesters: [Semester] { get }

  var selectedSemesterID: Semester.ID? { get set }
  var selectedTimetableID: Timetable.ID? { get set }

  var selectedSemester: Semester? { get }
  var selectedTimetable: Timetable? { get }

  func load() async throws
  func createTable() async throws
}

@Observable
final class TimetableUseCase: TimetableUseCaseProtocol {
  // MARK: - Properties
  private var store: [Semester.ID: [Timetable]] = [:]
  private(set) var semesters: [Semester] = []

  var selectedSemesterID: Semester.ID? = nil {
    didSet {
      if let selectedSemesterID {
        selectedTimetableID = "\(selectedSemesterID)-myTable"
      }
    }
  }
  var selectedTimetableID: Timetable.ID? = nil

  // MARK: - Dependencies
  private let userUseCase: UserUseCaseProtocol
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol

  // MARK: - Initialiser
  init(userUseCase: UserUseCaseProtocol, otlTimetableRepository: OTLTimetableRepositoryProtocol) {
    self.userUseCase = userUseCase
    self.otlTimetableRepository = otlTimetableRepository
  }

  var selectedSemester: Semester? {
    guard let id = selectedSemesterID else { return nil }
    return semesters.first(where: { $0.id == id })
  }

  var selectedTimetable: Timetable? {
    guard let sid = selectedSemesterID,
          let tid = selectedTimetableID else { return nil }
    return store[sid]?.first(where: { $0.id == tid })
  }

  func load() async throws {
    guard store.isEmpty || semesters.isEmpty else { return }

    async let fetchSemesters = otlTimetableRepository.getSemesters()
    async let fetchCurrentSemesters = otlTimetableRepository.getCurrentSemester()

    let (fetchedSemesters, fetchedCurrentSemester) = try await (
      fetchSemesters,
      fetchCurrentSemesters
    )

    semesters = fetchedSemesters

    // Put lectures user took into a My Table
    let user: OTLUser? = await userUseCase.otlUser
    store = Dictionary(
      uniqueKeysWithValues: semesters.map { semester in
        let lectures = user?.myTimetableLectures.filter {
          $0.year == semester.year && $0.semester == semester.semesterType
        } ?? []

        return (semester.id, [Timetable(id: "\(semester.id)-myTable", lectures: lectures)])
      }
    )

    // Select current semester if it exists in fetchedSemesters
    if let matchedSemester = semesters.first(where: {
      $0.year == fetchedCurrentSemester.year && $0.semesterType == fetchedCurrentSemester.semesterType
    }) {
      selectedSemesterID = matchedSemester.id
    } else {
      selectedSemesterID = semesters.last?.id
    }

    // Select My Table for that semester
    if let selectedSemesterID {
      selectedTimetableID = "\(selectedSemesterID)-myTable"
    }

    if let user = user,
       let selectedSemester = selectedSemester {
      let tables: [Timetable] = try await otlTimetableRepository.getTables(
        userID: user.id,
        year: selectedSemester.year,
        semester: selectedSemester.semesterType
      )
      logger.debug(tables)
    }
  }

  func createTable() async throws {
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

    // Insert into local store for the semester
    let sid = selectedSemester.id
    var tables = store[sid] ?? []

    // Avoid duplicates
    if !tables.contains(where: { $0.id == newTable.id }) {
      // Keep "myTable" first if present; append others after it
      if let myIdx = tables.firstIndex(where: { $0.id.hasSuffix("-myTable") }) {
        let head = tables[..<tables.index(after: myIdx)]
        let tail = tables[tables.index(after: myIdx)...]
        tables = Array(head) + [newTable] + Array(tail)
      } else {
        tables.append(newTable)
      }
    }

    store[sid] = tables
    selectedTimetableID = newTable.id
    logger.debug("Added table \(newTable.id) to semester \(sid). Total: \(tables.count)")
  }
}

