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
  public var showAlert: Bool = false
  public var alertMessage: LocalizedStringResource = ""
  
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
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol

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

  func selectPreviousSemester() async {
    guard let selectedSemesterID = timetableUseCase.selectedSemesterID,
          let currentIndex = timetableUseCase.semesters.firstIndex(where: { $0.id == selectedSemesterID }),
          currentIndex > 0 else {
      return
    }
    await timetableUseCase.selectSemester(timetableUseCase.semesters[currentIndex - 1].id)
  }

  func selectNextSemester() async {
    guard let selectedSemesterID = timetableUseCase.selectedSemesterID,
          let currentIndex = timetableUseCase.semesters.firstIndex(where: { $0.id == selectedSemesterID }),
          currentIndex < timetableUseCase.semesters.count - 1 else {
      return
    }
    await timetableUseCase.selectSemester(timetableUseCase.semesters[currentIndex + 1].id)
  }

  func selectTimetable(id: String) {
    timetableUseCase.selectedTimetableID = id
  }

  func createTable() async {
    do {
      try await timetableUseCase.createTable()
    } catch {
      handleException(error: error, type: .createTable)
    }
  }

  func deleteTable() async {
    do {
      try await timetableUseCase.deleteTable()
    } catch {
      handleException(error: error, type: .deleteTable)
    }
  }

  func addLecture(lecture: Lecture) async {
    do {
      try await timetableUseCase.addLecture(lecture: lecture)
    } catch {
      handleException(error: error, type: .addLecture)
    }
  }

  func deleteLecture(lecture: Lecture) async {
    do {
      try await timetableUseCase.deleteLecture(lecture: lecture)
    } catch {
      handleException(error: error, type: .deleteLecture)
    }
  }
  
  private func handleException(error: Error, type: ErrorType) {
    defer { showAlert = true }
    
    self.alertMessage = {
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
    }()
      
    if error.isNetworkMoyaError {
      alertMessage = "You are not connected to the Internet."
      return
    }
    
    crashlyticsService.recordException(error: error)
  }
}


