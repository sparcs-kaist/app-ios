//
//  TimetableViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 31/12/2024.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
final class TimetableViewModel {
  enum ErrorType: Equatable {
    case addLecture
    case createTable
    case deleteTable
    case deleteLecture
    case fetchData
  }
  
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

  var timetableIDsForSelectedSemester: [String] {
    timetableUseCase.timetableIDsForSelectedSemester
  }

  var selectedTimetableDisplayName: String {
    timetableUseCase.selectedTimetableDisplayName
  }

  var candidateLecture: Lecture? = nil
  var isCandidateOverlapping: Bool {
    guard let timetable = timetableUseCase.selectedTimetable,
          let candidateLecture = candidateLecture else { return false }

    return timetable.hasCollision(with: candidateLecture)
  }

  var isEditable: Bool {
    return timetableUseCase.isEditable
  }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.timetableUseCase
  ) private var timetableUseCase: TimetableUseCaseProtocol
  @ObservationIgnored @Injected(\.crashlyticsHelper) private var crashlyticsHelper: CrashlyticsHelper

  // MARK: - Functions

  func fetchData() async {
    isLoading = true
    defer { isLoading = false }

    do {
      try await timetableUseCase.load()
    } catch {
      handleException(error: error, type: .fetchData) // TODO: Display error in a way other than .alert()
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

  func selectTimetable(id: String) {
    timetableUseCase.selectedTimetableID = id
  }

  func createTable() async throws {
    try await timetableUseCase.createTable()
  }

  func deleteTable() async throws {
    try await timetableUseCase.deleteTable()
  }

  func addLecture(lecture: Lecture) async throws {
    try await timetableUseCase.addLecture(lecture: lecture)
  }

  func deleteLecture(lecture: Lecture) async throws {
    try await timetableUseCase.deleteLecture(lecture: lecture)
  }
  
  func handleException(error: Error, type: ErrorType) {
    var alertMessage: LocalizedStringResource {
      switch type {
      case .addLecture:
        "An unexpected error occurred while adding a lecture. Please try again later."
      case .createTable:
        "An unexpected error occurred while creating a new timetable. Please try again later."
      case .deleteLecture:
        "An unexpected error occurred while removing a lecture. Please try again later."
      case .deleteTable:
        "An unexpected error occurred while deleting a timetable. Please try again later."
      case .fetchData:
        "An unexpected error occurred while loading timetables. Please try again later."
      }
    }
    crashlyticsHelper.recordException(error: error, alertMessage: alertMessage)
  }
}


