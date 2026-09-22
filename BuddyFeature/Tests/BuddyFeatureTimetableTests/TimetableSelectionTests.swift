import Testing
import Foundation
import Observation
import Factory
import BuddyDomain
@testable import BuddyFeatureTimetable

@MainActor
struct TimetableSelectionTests {
  init() {
    Container.shared.v2TimetableUseCase.register { nil }
    Container.shared.crashlyticsService.register { nil }
    Container.shared.analyticsService.register { nil }
  }

  private var archived: Semester {
    .init(year: 2024, semesterType: .autumn, beginDate: Semester.mock.beginDate,
          endDate: Semester.mock.endDate, eventDate: Semester.mock.eventDate)
  }

  @Test func restoresTimetableAndOlderSemesterWithNewViewModel() async {
    let suite = "TimetableSelectionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let api = SelectionUseCase(semesters: [archived, .mock], tableID: 44)
    let first = TimetableViewModel(selectionStore: .init(defaults: defaults), timetableUseCase: api)
    first.selectedSemester = archived
    first.selectedTimetableID = 44
    let restored = TimetableViewModel(selectionStore: .init(defaults: UserDefaults(suiteName: suite)!), timetableUseCase: api)
    await restored.setup()
    await restored.updateTimetableList()
    await restored.loadTimetable()
    #expect(restored.selectedSemester == archived)
    #expect(restored.selectedTimetableID == 44)
    #expect(restored.timetable?.id == "44")
  }

  @Test func restoresMyTableInsteadOfAFormerSelection() async {
    let suite = "TimetableSelectionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let api = SelectionUseCase(semesters: [archived, .mock], tableID: 44)
    let first = TimetableViewModel(selectionStore: .init(defaults: defaults), timetableUseCase: api)
    first.selectedSemester = archived
    first.selectedTimetableID = 44
    first.selectedTimetableID = nil
    let restored = TimetableViewModel(selectionStore: .init(defaults: defaults), timetableUseCase: api)
    await restored.setup()
    await restored.loadTimetable()
    #expect(restored.selectedSemester == archived)
    #expect(restored.selectedTimetableID == nil)
    #expect(restored.timetable?.id == "my")
  }

  @Test func deletedTimetableFallsBackAndUpdatesPreference() async {
    let suite = "TimetableSelectionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TimetableSelectionStore(defaults: defaults)
    store.save(semester: archived, timetableID: 44)
    let api = SelectionUseCase(semesters: [archived, .mock], tableID: nil)
    let model = TimetableViewModel(selectionStore: store, timetableUseCase: api)
    await model.setup()
    await model.updateTimetableList()
    #expect(model.selectedTimetableID == nil)
    #expect(store.selection?.timetableID == nil)
  }

  @Test func failedListRefreshKeepsSelection() async {
    let suite = "TimetableSelectionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TimetableSelectionStore(defaults: defaults)
    store.save(semester: archived, timetableID: 44)
    let api = SelectionUseCase(semesters: [archived, .mock], tableID: 44)
    api.isOffline = true
    let model = TimetableViewModel(selectionStore: store, timetableUseCase: api)
    await model.setup()
    await model.updateTimetableList()
    #expect(model.selectedTimetableID == 44)
    #expect(store.selection?.timetableID == 44)
  }

  @Test func unavailableSemesterFallsBackToCurrentAndSignOutClearsPreference() async {
    let suite = "TimetableSelectionTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TimetableSelectionStore(defaults: defaults)
    store.save(semester: archived, timetableID: 44)
    let model = TimetableViewModel(selectionStore: store, timetableUseCase: SelectionUseCase(semesters: [.mock], tableID: nil))
    await model.setup()
    #expect(model.selectedSemester == .mock)
    #expect(model.selectedTimetableID == nil)
    store.clear()
    #expect(store.selection == nil)
  }

  @Test func coldOfflineLaunchRestoresNavigationAndContentsAndBlocksEdits() async throws {
    let suite = "TimetableOffline.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TimetableSelectionStore(defaults: defaults)
    store.save(semester: archived, timetableID: 44)
    let api = SelectionUseCase(semesters: [archived, .mock], tableID: 44)
    let table = Timetable(id: "44", lectures: [Lecture.mock])
    api.cached = .init(semesters: [archived, .mock], currentSemester: .mock,
      timetables: [.init(id: 44, title: "Saved", year: archived.year, semester: archived.semesterType)],
      timetable: table, updatedAt: .distantPast)
    api.allReadsOffline = true
    let model = TimetableViewModel(selectionStore: store, timetableUseCase: api)
    await model.refresh()
    #expect(model.selectedSemester == archived)
    #expect(model.selectedTimetableID == 44)
    #expect(model.timetable == table)
    #expect(model.timetables.first?.title == "Saved")
    #expect(model.lastUpdated == .distantPast)
    #expect(model.isShowingSavedData && model.isOffline && model.isReadOnly)
    #expect(!model.isAlertPresented)
    await model.deleteTable()
    await model.addLecture(lecture: .mock)
    await model.renameTable(title: "Changed")
    await #expect(throws: NetworkError.self) {
      try await model.saveActivity(timetableID: 44, activityID: nil,
        draft: .init(title: "Study", location: "", day: .mon, begin: 600, end: 660))
    }
    #expect(api.mutationCount == 0)
    #expect(store.selection?.timetableID == 44)

    // Fresh contents must replace saved contents in the visible screen.
    api.allReadsOffline = false
    api.onTableRequest = { #expect(model.timetable == table) }
    await model.refresh()
    #expect(model.timetable?.lectures.isEmpty == true)
    #expect(!model.isShowingSavedData && !model.isOffline && !model.isReadOnly)
    #expect(model.loadError == nil)
  }

  @Test func offlineCacheMissDoesNotShowPreviousTableAndCanRecover() async {
    let suite = "TimetableOffline.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let api = SelectionUseCase(semesters: [.mock], tableID: 44)
    api.cached = .init(semesters: [.mock], currentSemester: .mock,
      timetable: Timetable(id: "44", lectures: [Lecture.mock]))
    api.allReadsOffline = true
    let model = TimetableViewModel(selectionStore: .init(defaults: defaults), timetableUseCase: api)
    model.selectedSemester = .mock
    model.selectedTimetableID = 44
    await model.loadTimetable()
    #expect(model.timetable?.id == "44")
    model.selectedTimetableID = 45
    await model.loadTimetable()
    #expect(model.timetable == nil)
    #expect(model.loadError != nil)
    #expect(model.isReadOnly)
  }

  @Test func coldOfflineLaunchWithoutCacheRecoversOnRefresh() async {
    let suite = "TimetableOffline.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let api = SelectionUseCase(semesters: [.mock], tableID: nil)
    api.allReadsOffline = true
    let model = TimetableViewModel(selectionStore: .init(defaults: defaults), timetableUseCase: api)
    await model.refresh()
    #expect(model.timetable == nil && model.loadError != nil)
    api.allReadsOffline = false
    await model.refresh()
    #expect(model.selectedSemester == .mock)
    #expect(model.timetable?.id == "my")
    #expect(!model.isReadOnly && model.loadError == nil)
  }

  @Test func oldTableResponseCannotOverwriteANewSelection() async {
    let suite = "TimetableOffline.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let api = SelectionUseCase(semesters: [.mock], tableID: 44)
    let model = TimetableViewModel(selectionStore: .init(defaults: defaults), timetableUseCase: api)
    model.selectedSemester = .mock
    model.selectedTimetableID = 44
    api.isOffline = true // The list cannot invalidate either selection in this test.
    api.onTableRequest = {
      if model.selectedTimetableID == 44 { model.selectedTimetableID = 45 }
    }
    await model.loadTimetable()
    await model.loadTimetable()
    #expect(model.selectedTimetableID == 45)
    #expect(model.timetable?.id == "45")
  }

  @Test func incompleteSavedSemestersDoNotOverwritePersistedSelection() async {
    let suite = "TimetableOffline.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TimetableSelectionStore(defaults: defaults)
    store.save(semester: archived, timetableID: 44)
    let api = SelectionUseCase(semesters: [archived, .mock], tableID: 44)
    api.cached = .init(semesters: [.mock], currentSemester: .mock)
    api.allReadsOffline = true
    let model = TimetableViewModel(selectionStore: store, timetableUseCase: api)
    await model.setup()
    #expect(model.selectedSemester == nil)
    #expect(store.selection?.matches(archived) == true)
    #expect(store.selection?.timetableID == 44)
    api.allReadsOffline = false
    await model.refresh()
    #expect(model.selectedSemester == archived && model.selectedTimetableID == 44)
  }

  @Test func staleSavedListCannotEraseSelectionAndAuthFailureIsNotShownAsFreshData() async {
    let suite = "TimetableOffline.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = TimetableSelectionStore(defaults: defaults)
    store.save(semester: .mock, timetableID: 44)
    let api = SelectionUseCase(semesters: [.mock], tableID: 44)
    api.cached = .init(semesters: [.mock], currentSemester: .mock, timetables: [],
      timetable: Timetable(id: "44", lectures: [Lecture.mock]))
    api.allReadsOffline = true
    let model = TimetableViewModel(selectionStore: store, timetableUseCase: api)
    await model.refresh()
    #expect(model.selectedTimetableID == 44 && model.timetable?.id == "44")
    #expect(store.selection?.timetableID == 44)
    api.tableError = AuthUseCaseError.refreshFailed(NetworkError.noConnection)
    await model.loadTimetable()
    #expect(model.timetable?.id == "44")
    api.tableError = NetworkError.unauthorized
    await model.loadTimetable()
    #expect(model.timetable == nil)
    #expect(model.isReadOnly && model.loadError != nil)
  }
}

@MainActor @Observable
private final class SelectionUseCase: TimetableUseCaseProtocol {
  let semesters: [Semester]
  let tableID: Int?
  var isOffline = false
  var allReadsOffline = false
  var cached = TimetableCachedState()
  var mutationCount = 0
  var onTableRequest: (() -> Void)?
  var tableError: Error?

  func cachedState(semester: Semester?, timetableID: Int?) async -> TimetableCachedState {
    var result = cached
    if let timetableID, result.timetable?.id != String(timetableID) { result.timetable = nil }
    if timetableID == nil { result.timetable = nil }
    return result
  }

  init(semesters: [Semester], tableID: Int?) { self.semesters = semesters; self.tableID = tableID }
  func getSemesters() async throws -> [Semester] {
    if allReadsOffline { throw NetworkError.noConnection }
    return semesters
  }
  func getCurrentSemesters() async throws -> Semester {
    if allReadsOffline { throw NetworkError.noConnection }
    return .mock
  }
  func getTimetableList(semester: Semester) async throws -> [TimetableSummary] {
    if isOffline || allReadsOffline { throw NetworkError.noConnection }
    return tableID.map { [.init(id: $0, title: "Saved", year: semester.year, semester: semester.semesterType)] } ?? []
  }
  func getTable(id: Int) async throws -> Timetable {
    onTableRequest?()
    if let tableError { throw tableError }
    if allReadsOffline { throw NetworkError.noConnection }
    return .init(id: String(id), lectures: [])
  }
  func getMyTable(semester: Semester) async throws -> Timetable {
    if allReadsOffline { throw NetworkError.noConnection }
    return .init(id: "my", lectures: [])
  }
  func refreshTable(id: Int) async throws -> Timetable { try await getTable(id: id) }
  func deleteTable(id: Int) async throws { mutationCount += 1 }
  func renameTable(id: Int, title: String) async throws { mutationCount += 1 }
  func createTable(semester: Semester) async throws -> TableCreation { throw NetworkError.notFound }
  func duplicateMyTable(semester: Semester, title: String) async throws -> TableDuplication { throw NetworkError.notFound }
  func addLecture(timetableID: Int, lectureID: Int) async throws { mutationCount += 1 }
  func deleteLecture(timetableID: Int, lectureID: Int) async throws { }
  func saveActivity(timetableID: Int, activityID: Int?, draft: TimetableActivityDraft) async throws -> Timetable { throw NetworkError.notFound }
  func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable { throw NetworkError.notFound }
}
