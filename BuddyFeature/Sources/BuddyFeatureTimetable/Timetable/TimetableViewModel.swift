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
import WidgetKit

@MainActor
@Observable
public final class TimetableViewModel {
  @ObservationIgnored @Injected(
    \.v2TimetableUseCase
  ) private var timetableUseCase: TimetableUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  public var alertState: AlertState? = nil
  public var isAlertPresented: Bool = false

  @ObservationIgnored private let selectionStore: TimetableSelectionStore

  public var semesters: [Semester] = []
  public var selectedSemester: Semester? = nil {
    didSet {
      guard selectedSemester != oldValue else { return }
      timetableListTask?.cancel()
      timetableLoadTask?.cancel()
      timetables = []
      timetable = nil
      candidateLecture = nil
      if let selectedSemester, let saved = selectionStore.selection, saved.matches(selectedSemester) {
        selectedTimetableID = saved.timetableID
      } else {
        selectedTimetableID = nil
      }
      timetableListTask = Task {
        await updateTimetableList()
      }
    }
  }

  @ObservationIgnored private var timetableListTask: Task<Void, Never>?
  @ObservationIgnored private var timetableLoadTask: Task<Void, Never>?

  var timetables: [TimetableSummary] = []
  var selectedTimetableID: Int? = nil {
    didSet {
      if let selectedSemester {
        selectionStore.save(semester: selectedSemester, timetableID: selectedTimetableID)
      }
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

  public init(selectionStore: TimetableSelectionStore = .init(), timetableUseCase: TimetableUseCaseProtocol? = nil) {
    self.selectionStore = selectionStore
    if let timetableUseCase { self.timetableUseCase = timetableUseCase }
  }

  public func setup() async {
    guard let timetableUseCase else { return }

    isLoading = true
    defer { isLoading = false }

    do {
      semesters = try await timetableUseCase.getSemesters()
      if let saved = selectionStore.selection, let semester = semesters.first(where: saved.matches) {
        selectedSemester = semester
      } else {
        selectedSemester = try await timetableUseCase.getCurrentSemesters()
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to load semesters.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func addLecture(lecture: Lecture) async {
    guard let timetableUseCase,
          let selectedTimetableID else { return }

    do {
      let current = try await timetableUseCase.refreshTable(id: selectedTimetableID)
      guard !current.activities.contains(where: { activity in
        lecture.classes.contains { activity.draft.overlaps(day: $0.day, begin: $0.begin, end: $0.end) }
      }) else { throw TimetableActivityError.overlap }
      try await timetableUseCase.addLecture(timetableID: selectedTimetableID, lectureID: lecture.id)
      analyticsService?.logEvent(TimetableViewEvent.lectureAdded)
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
			WidgetCenter.shared.reloadAllTimelines()
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to add lecture.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func saveActivity(timetableID: Int, activityID: Int?, draft: TimetableActivityDraft) async throws {
    guard let timetableUseCase else { throw NetworkError.unauthorized }
    timetableLoadTask?.cancel()
    let updated = try await timetableUseCase.saveActivity(timetableID: timetableID, activityID: activityID, draft: draft)
    if selectedTimetableID == timetableID { timetable = updated }
    WidgetCenter.shared.reloadAllTimelines()
  }

  func refreshActivities(timetableID: Int) async throws {
    guard let timetableUseCase else { throw NetworkError.unauthorized }
    timetableLoadTask?.cancel()
    let updated = try await timetableUseCase.refreshTable(id: timetableID)
    if selectedTimetableID == timetableID { timetable = updated }
    WidgetCenter.shared.reloadAllTimelines()
  }

  func deleteActivity(_ activity: TimetableActivity) async {
    guard let timetableUseCase, let selectedTimetableID else { return }
    do {
      timetableLoadTask?.cancel()
      let updated = try await timetableUseCase.deleteActivity(timetableID: selectedTimetableID, activityID: activity.id)
      if self.selectedTimetableID == selectedTimetableID { timetable = updated }
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      alertState = .init(title: String(localized: "Unable to delete activity.", bundle: .module), message: error.localizedDescription)
      isAlertPresented = true
    }
  }

  func deleteLecture(lecture: Lecture) async {
    guard let timetableUseCase,
          let selectedTimetableID else { return }

    do {
      try await timetableUseCase.deleteLecture(timetableID: selectedTimetableID, lectureID: lecture.id)
      analyticsService?.logEvent(TimetableViewEvent.lectureDeleted)
      timetableLoadTask?.cancel()
      timetableLoadTask = Task {
        await loadTimetable()
      }
			WidgetCenter.shared.reloadAllTimelines()
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to delete lecture.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func loadTimetable() async {
    guard let timetableUseCase else { return }

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
			WidgetCenter.shared.reloadAllTimelines()
    } catch is CancellationError {
      // ignore
    } catch {
      crashlyticsService?.recordException(error: error)
      timetable = nil
    }
  }

  func updateTimetableList() async {
    guard let timetableUseCase,
          let selectedSemester
    else { return }

    do {
      let result = try await timetableUseCase.getTimetableList(semester: selectedSemester)

      try Task.checkCancellation()

      timetables = result
      // Only a successful list response can invalidate a restored selection.
      // A failed/offline refresh must not erase the user's preference.
      if let selectedTimetableID, !result.contains(where: { $0.id == selectedTimetableID }) {
        self.selectedTimetableID = nil
      }
    } catch is CancellationError {
      // ignore
    } catch {
      crashlyticsService?.recordException(error: error)
    }
  }

  func renameTable(title: String) async {
    guard let timetableUseCase,
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
			WidgetCenter.shared.reloadAllTimelines()
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to rename timetable.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func deleteTable() async {
    guard let timetableUseCase,
          let selectedTimetableID
    else { return }

    do {
      try await timetableUseCase.deleteTable(id: selectedTimetableID)
      if let index = timetables.firstIndex(where: { $0.id == selectedTimetableID }) {
        timetables.remove(at: index)
      }
      self.selectedTimetableID = nil

      analyticsService?.logEvent(TimetableViewEvent.tableDeleted)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
      }
			WidgetCenter.shared.reloadAllTimelines()
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to delete timetable.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  func createTable() async {
    guard let timetableUseCase,
          let selectedSemester else { return }

    do {
      let creation = try await timetableUseCase.createTable(semester: selectedSemester)
      analyticsService?.logEvent(TimetableViewEvent.tableCreated)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
        selectedTimetableID = creation.id
      }
			WidgetCenter.shared.reloadAllTimelines()
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to create timetable.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }
}
