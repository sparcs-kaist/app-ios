//
//  TimetableViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 31/12/2024.
//

import SwiftUI
import Observation
import Factory

@MainActor
@Observable
final class TimetableViewModel {
  var isLoading: Bool = false
  
  var semesters: [Semester] {
    timetableUseCase.semesters
  }

  var selectedSemester: Semester? {
    timetableUseCase.selectedSemester
  }

  var selectedTimetable: Timetable? {
    if let candidateLecture,
       var timetable = timetableUseCase.selectedTimetable {
      timetable.lectures.append(candidateLecture)

      return timetable
    }

    return timetableUseCase.selectedTimetable
  }

  var candidateLecture: Lecture? = nil

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.timetableUseCase
  ) private var timetableUseCase: TimetableUseCaseProtocol

  // MARK: - Functions

  func fetchData() async {
    isLoading = true
    defer { isLoading = false }

    do {
      try await timetableUseCase.load()
    } catch {
      // TODO: Handle error
    }
  }

  func selectPreviousSemester() {
    guard let selectedSemesterID = timetableUseCase.selectedSemesterID,
          let currentIndex = timetableUseCase.semesters.firstIndex(where: { $0.id == selectedSemesterID }),
          currentIndex >= 0 else {
      return
    }
    timetableUseCase.selectedSemesterID = timetableUseCase.semesters[currentIndex - 1].id
  }

  func selectNextSemester() {
    guard let selectedSemesterID = timetableUseCase.selectedSemesterID,
          let currentIndex = timetableUseCase.semesters.firstIndex(where: { $0.id == selectedSemesterID }),
          currentIndex >= 0 else {
      return
    }
    timetableUseCase.selectedSemesterID = timetableUseCase.semesters[currentIndex + 1].id
  }

  func createTable() async throws {
    try await timetableUseCase.createTable()
  }
}


