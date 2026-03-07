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
public final class V2TimetableViewModel {
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
  @ObservationIgnored private var timetableLoadTask: Task<Void, Never>?

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
  var selectedTimetableID: Int? = nil {
    didSet {
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
    }
  }
  var timetable: V2Timetable? = nil
  var timetableWithCandidate: V2Timetable? {
    guard let timetable else { return nil }

    if let candidateLecture {
      var table = timetable
      table.lectures.append(candidateLecture)

      return table
    }

    return timetable
  }
  var candidateLecture: V2Lecture? = nil

  var isLoading: Bool = true

  public init() { }

  public func setup() async {
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

  func addLecture(lecture: V2Lecture) async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedTimetableID else { return }

    do {
      try await timetableUseCase.addLecture(timetableID: selectedTimetableID, lectureID: lecture.id)
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
    } catch {
      // HANDLE EXCEPTION
    }
  }

  func deleteLecture(lecture: V2Lecture) async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedTimetableID else { return }

    do {
      try await timetableUseCase.deleteLecture(timetableID: selectedTimetableID, lectureID: lecture.id)
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
    } catch {
      // HANDLE EXCEPTION
    }
  }

  func loadTimetable() async {
    guard let timetableUseCase = v2TimetableUseCase else { return }

    do {
      let result: V2Timetable

      if let selectedTimetableID {
        result = try await timetableUseCase.getTable(id: selectedTimetableID)
      } else if let selectedSemester {
        result = try await timetableUseCase.getMyTable(semester: selectedSemester)
      } else {
        timetable = nil
        return
      }

      try Task.checkCancellation()

      timetable = result
    } catch is CancellationError {
      // ignore
    } catch {
      // HANDLE EXCEPTION
      timetable = nil
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

  func deleteTable() async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedTimetableID
    else { return }

    do {
      try await timetableUseCase.deleteTable(id: selectedTimetableID)
      if let index = timetables.firstIndex(where: { $0.id == selectedTimetableID }) {
        timetables.remove(at: index)
      }

      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
    } catch {
      // HANDLE EXCEPTION
    }
  }

  func createTable() async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedSemester else { return }

    do {
      let creation = try await timetableUseCase.createTable(semester: selectedSemester)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
        selectedTimetableID = creation.id
      }
    } catch {
      // HANDLE EXCEPTION
    }
  }
}
