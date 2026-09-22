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
import Network

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
      lastUpdated = nil
      isShowingSavedData = false
      loadError = nil
      refreshFailures.subtract(["list", "table"])
      offlineFailures.subtract(["list", "table"])
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
      if selectedTimetableID != oldValue {
        timetable = nil
        candidateLecture = nil
        lastUpdated = nil
        isShowingSavedData = false
        loadError = nil
      }
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
  public private(set) var isShowingSavedData = false
  public private(set) var lastUpdated: Date?
  public private(set) var loadError: String?
  private var refreshFailures: Set<String> = []
  private var offlineFailures: Set<String> = []
  private var networkUnavailable = false
  @ObservationIgnored private var loadGeneration = 0
  @ObservationIgnored private var listGeneration = 0
  @ObservationIgnored private var setupGeneration = 0
  @ObservationIgnored private var isRefreshing = false
  public var isOffline: Bool { networkUnavailable || !offlineFailures.isEmpty }
  public var isReadOnly: Bool { isOffline || !refreshFailures.isEmpty || isShowingSavedData }
  public var showsSavedStatus: Bool { isShowingSavedData || !refreshFailures.isEmpty || isOffline }
  /// Duplicating replays every lecture and activity, so it is slow enough that the
  /// menu entry must not be tappable twice.
  public var isDuplicatingTable: Bool = false

  public init(selectionStore: TimetableSelectionStore = .init(), timetableUseCase: TimetableUseCaseProtocol? = nil) {
    self.selectionStore = selectionStore
    if let timetableUseCase { self.timetableUseCase = timetableUseCase }
  }

  public func setup() async {
    guard let timetableUseCase else { return }
    setupGeneration += 1
    let generation = setupGeneration
    let cached = await timetableUseCase.cachedState(semester: nil, timetableID: nil)
    guard !Task.isCancelled, generation == setupGeneration else { return }
    if semesters.isEmpty { semesters = cached.semesters ?? [] }
    if selectedSemester == nil { restoreSelection(current: cached.currentSemester) }
    isLoading = semesters.isEmpty
    defer { if generation == setupGeneration { isLoading = false } }

    do {
      let fresh = try await timetableUseCase.refreshSemesters()
      try Task.checkCancellation()
      guard generation == setupGeneration else { return }
      semesters = fresh
      isLoading = false
      succeeded("semesters")
      restoreSelection(current: cached.currentSemester.flatMap { fresh.contains($0) ? $0 : nil }, authoritative: true)
    } catch is CancellationError { return }
    catch {
      guard !Task.isCancelled, generation == setupGeneration else { return }
      failed(error, resource: "semesters")
    }
    do {
      let current = try await timetableUseCase.refreshCurrentSemester()
      try Task.checkCancellation()
      guard generation == setupGeneration else { return }
      succeeded("current")
      restoreSelection(current: current, authoritative: !refreshFailures.contains("semesters"))
    } catch is CancellationError { return }
    catch {
      guard !Task.isCancelled, generation == setupGeneration else { return }
      failed(error, resource: "current")
    }
    if selectedSemester == nil {
      loadError = String(localized: "Connect to the internet to download your timetable.", bundle: .module)
    }
  }

  private func restoreSelection(current: Semester?, authoritative: Bool = false) {
    if let selectedSemester, semesters.contains(selectedSemester) { return }
    if let saved = selectionStore.selection {
      if let semester = semesters.first(where: saved.matches) {
        selectedSemester = semester
        return
      }
      // An incomplete saved semester list cannot invalidate a persisted preference.
      if !authoritative { return }
    }
    if let current { selectedSemester = current }
  }

  /// Also refresh navigation so an offline cold launch can recover.
  public func refresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    defer { isRefreshing = false }
    await setup()
    await updateTimetableList()
    await loadTimetable()
  }

  public func observeConnectivity() async {
    let monitor = NWPathMonitor()
    let changes = AsyncStream<Bool>(bufferingPolicy: .bufferingNewest(1)) { continuation in
      monitor.pathUpdateHandler = { continuation.yield($0.status == .satisfied) }
      continuation.onTermination = { _ in monitor.cancel() }
      monitor.start(queue: DispatchQueue(label: "org.sparcs.soap.timetable-connectivity"))
    }
    for await connected in changes {
      let shouldRefresh = connected && (networkUnavailable || !refreshFailures.isEmpty)
      networkUnavailable = !connected
      if shouldRefresh { await refresh() }
    }
  }

  private func succeeded(_ resource: String) {
    refreshFailures.remove(resource)
    offlineFailures.remove(resource)
  }

  private func failed(_ error: Error, resource: String) {
    refreshFailures.insert(resource)
    offlineFailures.remove(resource)
    if case NetworkError.noConnection = underlyingError(error) { offlineFailures.insert(resource) }
    crashlyticsService?.recordException(error: error)
  }

  private func underlyingError(_ error: Error) -> Error {
    if case AuthUseCaseError.refreshFailed(let cause) = error { return underlyingError(cause) }
    return error
  }

  private func canKeepSavedData(after error: Error) -> Bool {
    switch underlyingError(error) {
    case NetworkError.unauthorized, NetworkError.notFound, AuthUseCaseError.noAccessToken: return false
    default: return true
    }
  }

  private func requireOnline() throws {
    if isReadOnly { throw NetworkError.noConnection }
  }

  func addLecture(lecture: Lecture) async {
    guard !isReadOnly else { return }
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
    try requireOnline()
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
    guard !isReadOnly else { return }
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
    guard !isReadOnly else { return }
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
    guard let timetableUseCase, let semester = selectedSemester else { return }
    loadGeneration += 1
    let generation = loadGeneration
    let tableID = selectedTimetableID
    let cached = await timetableUseCase.cachedState(semester: semester, timetableID: tableID)
    guard !Task.isCancelled, generation == loadGeneration,
          selectedSemester == semester, selectedTimetableID == tableID else { return }
    if let table = cached.timetable {
      timetable = table
      lastUpdated = cached.updatedAt
      isShowingSavedData = true
      loadError = nil
    }

    do {
      let result: Timetable

      if let tableID {
        result = try await timetableUseCase.refreshTable(id: tableID)
      } else {
        result = try await timetableUseCase.refreshMyTable(semester: semester)
      }

      try Task.checkCancellation()
      guard generation == loadGeneration, selectedSemester == semester, selectedTimetableID == tableID else { return }
      timetable = result
      lastUpdated = .now
      isShowingSavedData = false
      loadError = nil
      succeeded("table")
			WidgetCenter.shared.reloadAllTimelines()
    } catch is CancellationError {
      // ignore
    } catch {
      guard !Task.isCancelled, generation == loadGeneration,
            selectedSemester == semester, selectedTimetableID == tableID else { return }
      failed(error, resource: "table")
      if !canKeepSavedData(after: error) { timetable = nil; lastUpdated = nil }
      isShowingSavedData = timetable != nil
      if timetable == nil {
        loadError = isOffline
          ? String(localized: "This timetable isn’t available offline. Connect to download it.", bundle: .module)
          : error.localizedDescription
      }
    }
  }

  func updateTimetableList() async {
    guard let timetableUseCase,
          let selectedSemester
    else { return }
    listGeneration += 1
    let generation = listGeneration
    let cached = await timetableUseCase.cachedState(semester: selectedSemester, timetableID: nil)
    guard !Task.isCancelled, generation == listGeneration, self.selectedSemester == selectedSemester else { return }
    if let saved = cached.timetables { timetables = saved }

    do {
      let result = try await timetableUseCase.refreshTimetableList(semester: selectedSemester)

      try Task.checkCancellation()
      guard generation == listGeneration, self.selectedSemester == selectedSemester else { return }
      timetables = result
      succeeded("list")
      // Only a successful list response can invalidate a restored selection.
      // A failed/offline refresh must not erase the user's preference.
      if let selectedTimetableID, !result.contains(where: { $0.id == selectedTimetableID }) {
        self.selectedTimetableID = nil
      }
    } catch is CancellationError {
      // ignore
    } catch {
      guard !Task.isCancelled, generation == listGeneration, self.selectedSemester == selectedSemester else { return }
      failed(error, resource: "list")
    }
  }

  func renameTable(title: String) async {
    guard !isReadOnly else { return }
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
    guard !isReadOnly else { return }
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
    guard !isReadOnly else { return }
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

  /// Copies "My Table" of the selected semester into a new table and selects it.
  func duplicateMyTable() async {
    guard !isReadOnly else { return }
    guard let timetableUseCase,
          let selectedSemester,
          !isDuplicatingTable else { return }

    isDuplicatingTable = true
    defer { isDuplicatingTable = false }

    do {
      let duplication = try await timetableUseCase.duplicateMyTable(
        semester: selectedSemester,
        title: duplicateTitle()
      )
      analyticsService?.logEvent(TimetableViewEvent.tableDuplicated)
      timetableListTask?.cancel()
      timetableListTask = Task {
        await updateTimetableList()
        selectedTimetableID = duplication.id
      }
      WidgetCenter.shared.reloadAllTimelines()

      // The table exists either way; tell the user only when it is incomplete.
      if !duplication.isComplete {
        alertState = .init(
          title: String(localized: "Timetable partially duplicated.", bundle: .module),
          message: String(localized: "Some lectures or activities could not be copied.", bundle: .module)
        )
        isAlertPresented = true
      }
    } catch {
      crashlyticsService?.recordException(error: error)
      alertState = .init(
        title: String(localized: "Unable to duplicate timetable.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }

  /// A title that does not clash with the semester's existing tables, so repeated
  /// duplicates stay distinguishable in the selector.
  private func duplicateTitle() -> String {
    let base = String(localized: "My Table Copy", bundle: .module)
    let existing = Set(timetables.map(\.title))

    guard existing.contains(base) else { return base }

    var index = 2
    while existing.contains("\(base) \(index)") {
      index += 1
    }
    return "\(base) \(index)"
  }
}
