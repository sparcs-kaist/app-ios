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
      // Do not clear selectedTimetableID when it appears in timetables
      if let selectedID = selectedTimetableID,
         timetables.contains(where: { $0.id == selectedID }) {
        return
      }

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

  func renameTable(title: String) async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedTimetableID
    else { return }

    do {
      try await timetableUseCase.renameTable(id: selectedTimetableID, title: title)

      if let index = timetables.firstIndex(where: { $0.id == selectedTimetableID }) {
        withAnimation(.spring) {
          timetables[index].title = title
        }
      }

      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
    } catch {
      // HANDLE EXCEPTION
    }
  }
}
