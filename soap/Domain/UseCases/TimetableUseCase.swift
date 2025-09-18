//
//  TimetableUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 17/09/2025.
//

import Foundation
import Observation

@MainActor
protocol TimetableUseCaseProtocol {
  var semesters: [Semester] { get }

  var selectedSemesterID: Semester.ID? { get set }
  var selectedTimetableID: Timetable.ID? { get set }

  var selectedSemester: Semester? { get }
  var selectedTimetable: Timetable? { get }

  func load() async throws
}

@Observable
final class TimetableUseCase: TimetableUseCaseProtocol {
  private var store: [Semester.ID: [Timetable]] = [:]
  private(set) var semesters: [Semester] = []

  var selectedSemesterID: Semester.ID? = nil
  var selectedTimetableID: Timetable.ID? = nil

  var selectedSemester: Semester? {
    guard let id = selectedSemesterID else { return nil }
    return semesters.first(where: { $0.id == id })
  }

  var selectedTimetable: Timetable? {
    guard let sid = selectedSemesterID,
          let tid = selectedTimetableID else {
      return nil
    }
    return store[sid]?.first(where: { $0.id == tid })
  }

  func load() async throws {
    semesters = Semester.mockList
    store = Dictionary(uniqueKeysWithValues: semesters.map { ($0.id, []) })

    selectedSemesterID = semesters.last?.id
  }
}
