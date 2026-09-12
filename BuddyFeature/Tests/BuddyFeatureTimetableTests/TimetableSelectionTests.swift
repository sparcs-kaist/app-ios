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
}

@MainActor @Observable
private final class SelectionUseCase: TimetableUseCaseProtocol {
  let semesters: [Semester]
  let tableID: Int?
  var isOffline = false

  init(semesters: [Semester], tableID: Int?) { self.semesters = semesters; self.tableID = tableID }
  func getSemesters() async throws -> [Semester] { semesters }
  func getCurrentSemesters() async throws -> Semester { .mock }
  func getTimetableList(semester: Semester) async throws -> [TimetableSummary] {
    if isOffline { throw NetworkError.noConnection }
    return tableID.map { [.init(id: $0, title: "Saved", year: semester.year, semester: semester.semesterType)] } ?? []
  }
  func getTable(id: Int) async throws -> Timetable { .init(id: String(id), lectures: []) }
  func getMyTable(semester: Semester) async throws -> Timetable { .init(id: "my", lectures: []) }
  func refreshTable(id: Int) async throws -> Timetable { try await getTable(id: id) }
  func deleteTable(id: Int) async throws { }
  func renameTable(id: Int, title: String) async throws { }
  func createTable(semester: Semester) async throws -> TableCreation { throw NetworkError.notFound }
  func addLecture(timetableID: Int, lectureID: Int) async throws { }
  func deleteLecture(timetableID: Int, lectureID: Int) async throws { }
  func saveActivity(timetableID: Int, activityID: Int?, draft: TimetableActivityDraft) async throws -> Timetable { throw NetworkError.notFound }
  func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable { throw NetworkError.notFound }
}
