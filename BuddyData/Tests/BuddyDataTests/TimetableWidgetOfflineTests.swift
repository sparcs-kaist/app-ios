import Testing
import Foundation
import SwiftData
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Timetable widget offline persistence")
struct TimetableWidgetOfflineTests {
  private let semesterJSON = #"{"year":2026,"semester":3,"beginning":"2026-09-01T00:00:00.000Z","end":"2026-12-20T00:00:00.000Z"}"#
  private let listJSON = #"{"semesters":[{"year":2026,"semester":3,"timetables":[{"id":42,"name":"My schedule"}]}]}"#

  @Test func currentTableSurvivesRepeatedOfflineRefreshesAndNewUseCases() async throws {
    let container = try makeContainer()
    let table = Timetable(id: "2026-autumn-myTable", lectures: [Lecture.mock])
    TimetableCache(modelContainer: container).storeCurrentMyTable(table)

    // Each widget invocation gets a new use case and cache, with no in-memory state.
    for _ in 0..<3 {
      let cache = TimetableCache(modelContainer: container)
      let widget = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
      #expect(await widget.getCurrentMyTable() == table)
      #expect(cache.currentMyTable() == table)
    }
  }

  @Test func oldWidgetDataSurvivesReopeningThePersistentStore() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let configuration = ModelConfiguration(url: directory.appendingPathComponent("widget.store"))
    let table = Timetable(id: "2026-autumn-myTable", lectures: [Lecture.mock])
    let list = [SemesterWithTimetables(year: 2026, semester: .autumn,
      timetables: [TimetableHeader(id: 42, name: "My schedule")])]
    do {
      let container = try ModelContainer(for: CachedTimetable.self, configurations: configuration)
      let cache = TimetableCache(modelContainer: container)
      cache.storeCurrentMyTable(table)
      cache.storeTimetableList(list)
      cache.storeSemesters([.mock])
      cache.storeCurrentSemester(.mock)
      cache.storeTimetableSummaries([.init(id: 42, title: "Saved", year: Semester.mock.year,
        semester: Semester.mock.semesterType)], semester: .mock)
      cache.store(Timetable(id: "42", lectures: [Lecture.mock]), forKey: "42")
      let context = ModelContext(container)
      for record in try context.fetch(FetchDescriptor<CachedTimetable>()) {
        record.updatedAt = .distantPast
      }
      try context.save()
    }

    let reopened = try ModelContainer(for: CachedTimetable.self, configurations: configuration)
    let widget = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(),
      cache: TimetableCache(modelContainer: reopened))
    #expect(await widget.getCurrentMyTable() == table)
    #expect(await widget.getTableList() == list)
    let app = TimetableUseCase(otlTimetableRepository: offlineRepository(), cache: TimetableCache(modelContainer: reopened))
    let state = await app.cachedState(semester: .mock, timetableID: 42)
    #expect(state.semesters == [.mock])
    #expect(state.currentSemester == .mock)
    #expect(state.timetables?.first?.title == "Saved")
    #expect(state.timetable?.lectures == [Lecture.mock])
    #expect(state.updatedAt == .distantPast)
    #expect(try await app.getSemesters() == [.mock])
    #expect(try await app.getCurrentSemesters() == .mock)
    await #expect(throws: NetworkError.self) { try await app.refreshSemesters() }
    await #expect(throws: NetworkError.self) { try await app.refreshTable(id: 42) }
    #expect(await app.cachedState(semester: .mock, timetableID: 42).timetable == state.timetable)
    TimetableCache(modelContainer: reopened).clear()
    let cleared = await app.cachedState(semester: .mock, timetableID: 42)
    #expect(cleared.semesters == nil && cleared.currentSemester == nil && cleared.timetables == nil && cleared.timetable == nil)
  }

  @Test func appRefreshPersistsNavigationAndUpdatesVisibleCache() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    let api = repository { target in
      switch target {
      case .fetchSemesters: return self.response("{\"semesters\":[\(semesterJSON)]}")
      case .fetchCurrentSemester: return self.response(semesterJSON)
      case .fetchTables: return self.response(#"{"timetables":[{"id":42,"name":"Fresh","year":2026,"semester":3,"timeTableOrder":0}]}"#)
      case .fetchActivities: return self.response(#"{"custom_blocks":[]}"#)
      default: return self.response(#"{"lectures":[]}"#)
      }
    }
    let app = TimetableUseCase(otlTimetableRepository: api, cache: cache)
    let semesters = try await app.refreshSemesters()
    let current = try await app.refreshCurrentSemester()
    let list = try await app.refreshTimetableList(semester: current)
    let table = try await app.refreshTable(id: 42)
    let state = await app.cachedState(semester: current, timetableID: 42)
    #expect(state.semesters == semesters)
    #expect(state.currentSemester == current)
    #expect(state.timetables == list)
    #expect(state.timetable == table)
    #expect(state.updatedAt != nil)
    try await app.renameTable(id: 42, title: "Renamed")
    #expect(await app.cachedState(semester: current, timetableID: 42).timetables?.first?.title == "Renamed")
    #expect(await app.cachedState(semester: current, timetableID: 42).timetable == table)
    try await app.deleteTable(id: 42)
    let deleted = await app.cachedState(semester: current, timetableID: 42)
    #expect(deleted.timetables?.isEmpty == true && deleted.timetable == nil)
    let myTable = try await app.refreshMyTable(semester: current)
    #expect(await app.cachedState(semester: current, timetableID: nil).timetable == myTable)
    let archive = Semester.mock
    #expect(await app.cachedState(semester: archive, timetableID: nil).timetable == nil)
    #expect(await app.cachedState(semester: archive, timetableID: nil).timetables == nil)
  }

  @Test func successfulRefreshPersistsCurrentTableAndReplacesOldContents() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    cache.storeCurrentMyTable(Timetable(id: "old-myTable", lectures: [Lecture.mock]))
    let repository = repository { target in
      if case .fetchCurrentSemester = target { return self.response(semesterJSON) }
      return self.response(#"{"lectures":[]}"#)
    }
    let online = TimetableUseCaseBackground(otlTimetableRepository: repository, cache: cache)
    let fresh = await online.getCurrentMyTable()
    #expect(fresh.id != "old-myTable")
    #expect(fresh.id != "-myTable")
    #expect(fresh.lectures.isEmpty)
    #expect(cache.currentMyTable() == fresh)
    #expect(cache.timetable(forKey: fresh.id) == fresh)

    let offline = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
    #expect(await offline.getCurrentMyTable() == fresh)
  }

  @Test func tableRequestFailureUsesMatchingSemesterCache() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    let key = "2026-\(SemesterType.autumn.rawValue)-myTable"
    let table = Timetable(id: key, lectures: [Lecture.mock])
    cache.store(table, forKey: key)
    let repository = repository { target in
      if case .fetchCurrentSemester = target { return self.response(semesterJSON) }
      return .networkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
    }
    let widget = TimetableUseCaseBackground(otlTimetableRepository: repository, cache: cache)
    #expect(await widget.getCurrentMyTable() == table)
  }

  @Test func selectedTimetableRetainsLecturesAndActivitiesOffline() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    var table = Timetable(id: "42", lectures: [Lecture.mock])
    table.activities = [TimetableActivity(id: 17, title: "Study", location: "Library", day: .thu, begin: 1020, end: 1170)]
    cache.store(table, forKey: "42")
    let widget = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
    #expect(await widget.getTable(timetableID: 42) == table)
  }

  @Test func timetableOptionsSurviveOfflineRefreshAndAcceptFreshEmptyList() async throws {
    let container = try makeContainer()
    let online = TimetableUseCaseBackground(
      otlTimetableRepository: repository { _ in self.response(listJSON) },
      cache: TimetableCache(modelContainer: container)
    )
    let list = await online.getTableList()
    #expect(list.first?.timetables.first?.id == 42)

    let cache = TimetableCache(modelContainer: container)
    let offline = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
    #expect(await offline.getTableList() == list)
    #expect(await offline.getTableList() == list)

    let empty = TimetableUseCaseBackground(
      otlTimetableRepository: repository { _ in self.response(#"{"semesters":[]}"#) }, cache: cache
    )
    #expect(await empty.getTableList().isEmpty)
    #expect(await offline.getTableList().isEmpty)
  }

  @Test func signOutClearsWidgetDataAndColdOfflineLoadIsEmpty() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    cache.storeCurrentMyTable(Timetable(id: "2026-autumn-myTable", lectures: [Lecture.mock]))
    cache.storeTimetableList([SemesterWithTimetables(year: 2026, semester: .autumn,
      timetables: [TimetableHeader(id: 42, name: "My schedule")])])
    cache.clear()
    #expect(cache.currentMyTable() == nil)
    #expect(cache.timetableList() == nil)
    let offline = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
    #expect(await offline.getCurrentMyTable().lectures.isEmpty)
    #expect(await offline.getTableList().isEmpty)
  }

  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(for: CachedTimetable.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
  }

  private func response(_ json: String) -> EndpointSampleResponse {
    .networkResponse(200, Data(json.utf8))
  }

  private func offlineRepository() -> OTLTimetableRepository {
    repository { _ in .networkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)) }
  }

  private func repository(_ response: @escaping @Sendable (OTLTimetableTarget) -> EndpointSampleResponse) -> OTLTimetableRepository {
    OTLTimetableRepository(provider: MoyaProvider<OTLTimetableTarget>(endpointClosure: { target in
      Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { response(target) }, method: target.method,
        task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub))
  }
}
