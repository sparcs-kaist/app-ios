//
//  TimetableViewModel.swift
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
public final class TimetableViewModel {
  @ObservationIgnored @Injected(
    \.v2TimetableUseCase
  ) private var v2TimetableUseCase: TimetableUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  public var alertState: AlertState? = nil
  public var isAlertPresented: Bool = false

  public var semesters: [Semester] = []
  public var selectedSemester: Semester? = nil {
    didSet {
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
    }
  }

  @ObservationIgnored private var timetableListTask: Task<Void, Never>?
  @ObservationIgnored private var timetableLoadTask: Task<Void, Never>?

  var timetables: [TimetableSummary] = [] {
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
  public var timetable: Timetable? = nil
  var timetableWithCandidate: Timetable? {
    guard let timetable else { return nil }

    if let candidateLecture {
      var table = timetable
      table.lectures.append(candidateLecture)

      return table
    }

    return timetable
  }
  var candidateLecture: Lecture? = nil

  public var isLoading: Bool = true

  public init() { }

  public func setup() async {
    guard let timetableUseCase = v2TimetableUseCase else { return }

    isLoading = true
    defer { isLoading = false }

    do {
      semesters = try await timetableUseCase.getSemesters()
      selectedSemester = try await timetableUseCase.getCurrentSemesters()
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to load semesters."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func addLecture(lecture: Lecture) async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedTimetableID else { return }

    do {
      try await timetableUseCase.addLecture(timetableID: selectedTimetableID, lectureID: lecture.id)
      analyticsService?.logEvent(TimetableViewEvent.lectureAdded)
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to add lecture."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func deleteLecture(lecture: Lecture) async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedTimetableID else { return }

    do {
      try await timetableUseCase.deleteLecture(timetableID: selectedTimetableID, lectureID: lecture.id)
      analyticsService?.logEvent(TimetableViewEvent.lectureDeleted)
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to delete lecture."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func loadTimetable() async {
    guard let timetableUseCase = v2TimetableUseCase else { return }

    do {
      let result: Timetable

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
      crashlyticsService?.recordException(error: error)
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
      crashlyticsService?.recordException(error: error)
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

      analyticsService?.logEvent(TimetableViewEvent.tableRenamed)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to rename timetable."),
        message: error.localizedDescription
      )
      isAlertPresented = true
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

      analyticsService?.logEvent(TimetableViewEvent.tableDeleted)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to delete timetable."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func createTable() async {
    guard let timetableUseCase = v2TimetableUseCase,
          let selectedSemester else { return }

    do {
      let creation = try await timetableUseCase.createTable(semester: selectedSemester)
      analyticsService?.logEvent(TimetableViewEvent.tableCreated)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
        selectedTimetableID = creation.id
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to create timetable."),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }
}
