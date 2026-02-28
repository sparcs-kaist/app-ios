//
//  V2TimetableViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
final class V2TimetableViewModel {
  @ObservationIgnored @Injected(
    \.v2TimetableUseCase
  ) private var v2TimetableUseCase: V2TimetableUseCaseProtocol?

  var semesters: [Semester] = []
  var selectedSemester: Semester? = nil {
    didSet {
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
    }
  }

  @ObservationIgnored private var timetableListTask: Task<Void, Never>?
  var timetables: [V2TimetableSummary] = [] {
    didSet {
      selectedTimetableID = nil
    }
  }
  var selectedTimetableID: Int? = nil
  var timetable: V2Timetable? = nil

  var isLoading: Bool = true

  func setup() async {
    guard let timetableUseCase = v2TimetableUseCase else { return }

    isLoading = true
    defer { isLoading = false }

    do {
      semesters = try await timetableUseCase.getSemesters()
      selectedSemester = try await timetableUseCase.getCurrentSemesters()
    } catch {
      // HANDLE EXCEPTION
    }
  }

  func updateTimetableList() async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedSemester
    else { return }

    do {
      let result = try await timetableUseCase.getTimetableList(semester: selectedSemester)

      try Task.checkCancellation()

      timetables = result
    } catch is CancellationError {
      // ignore
    } catch {
      // HANDLE EXCCEPTION
    }
  }
}
