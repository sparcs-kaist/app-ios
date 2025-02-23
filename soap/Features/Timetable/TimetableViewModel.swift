//
//  TimetableViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 31/12/2024.
//

import SwiftUI
import Observation

@Observable
class TimetableViewModel {
  var isLoading: Bool = true

  // Needs to be fetched
  var timetables: [Timetable] = [Timetable]()
  var selectedTimetable: Timetable?
  var semesters: [Semester] = [Semester]()
  var selectedSemester: Semester? {
    didSet {
      updateTimetablesForSelectedSemester()
    }
  }

  var timetablesForSelectedSemester: [Timetable] = [Timetable]()

  func fetchData() async {
    do {
      //            try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
      await MainActor.run {
        timetables = Timetable.mockList
        semesters = Array(Set(timetables.map(\.semester))).sorted()

        if let firstTimetable = timetables.first {
          selectedTimetable = firstTimetable
          selectedSemester = firstTimetable.semester
        }
        isLoading = false
      }
    } catch {
      print("[TimetableViewModel] fetchData failed.")
    }
  }

  func selectPreviousSemester() {
    guard let selectedSemester = selectedSemester,
          let currentIndex = semesters.firstIndex(of: selectedSemester),
          currentIndex >= 0 else {
      return
    }
    self.selectedSemester = semesters[currentIndex - 1]
  }

  func selectNextSemester() {
    guard let selectedSemester = selectedSemester,
          let currentIndex = semesters.firstIndex(of: selectedSemester),
          currentIndex >= 0 else {
      return
    }
    self.selectedSemester = semesters[currentIndex + 1]
  }

  // MARK: - Private Functions
  private func updateTimetablesForSelectedSemester() {
    if let selectedSemester = selectedSemester {
      timetablesForSelectedSemester = timetables.filter { $0.semester == selectedSemester }
      selectedTimetable = timetablesForSelectedSemester.first
    } else {
      timetablesForSelectedSemester = [Timetable]()
      selectedTimetable = nil
    }
  }
}

