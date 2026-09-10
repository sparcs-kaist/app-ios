import Testing
import Foundation
import SwiftData
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Timetable activities")
struct TimetableActivityTests {
  private let draft = TimetableActivityDraft(title: "Study", location: "Library", day: .thu, begin: 1020, end: 1170)
  private let blocks = #"{"custom_blocks":[{"id":17,"block_name":"Study","place":"Library","day":3,"begin":1020,"end":1170}]}"#

  @Test func decodesServerFieldsAndCachesActivities() async throws {
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: (200, #"{"lectures":[]}"#)
      default: (200, blocks)
      }
    }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    let result = try await useCase.getTable(id: 354045)
    #expect(result.activities.first?.id == 17)
    #expect(result.activities.first?.draft == draft)
    #expect(cache.timetable(forKey: "354045") == result)
    #expect(stub.paths == ["/api/v2/timetables/354045", "/api/v2/timetables/354045/custom-blocks"])
  }

  @Test func mutationRoutesAndPayloads() async throws {
    let stub = ActivityAPIStub { _ in (204, "") }
    let repository = stub.repository
    try await repository.createActivity(timetableID: 354045, draft: draft)
    try await repository.updateActivity(timetableID: 354045, activityID: 17, draft: draft)
    try await repository.deleteActivity(timetableID: 354045, activityID: 17)
    #expect(stub.targets.map(\.method) == [.post, .patch, .delete])
    #expect(stub.paths == ["/api/v2/timetables/354045/custom-blocks", "/api/v2/timetables/354045/custom-blocks/17", "/api/v2/timetables/354045/custom-blocks/17"])
    for target in stub.targets.prefix(2) {
      guard case .requestParameters(let payload, _) = target.task else { Issue.record("Expected JSON payload"); return }
      #expect(payload["block_name"] as? String == "Study")
      #expect(payload["place"] as? String == "Library")
      #expect(payload["day"] as? Int == 3)
      #expect(payload["begin"] as? Int == 1020)
      #expect(payload["end"] as? Int == 1170)
      #expect(payload.count == 5)
    }
  }

  @Test func saveAlwaysRefetchesAndUsesServerResult() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: return (200, #"{"lectures":[]}"#)
      case .createActivity: state.mutated = true; return (201, "")
      case .fetchActivities: return (200, state.mutated ? blocks : #"{"custom_blocks":[]}"#)
      default: return (500, "")
      }
    }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    let result = try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: draft)
    #expect(result.activities.first?.id == 17)
    #expect(cache.timetable(forKey: "354045")?.activities == result.activities)
    #expect(stub.targets.map(\.method) == [.get, .get, .post, .get, .get])
  }

  @Test func editingExcludesItselfAndDeletingRefetches() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: return (200, #"{"lectures":[]}"#)
      case .fetchActivities: return (200, state.mutated ? #"{"custom_blocks":[]}"# : blocks)
      case .deleteActivity: state.mutated = true; return (204, "")
      case .updateActivity: return (204, "")
      default: return (500, "")
      }
    }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    let updated = try await useCase.saveActivity(timetableID: 354045, activityID: 17, draft: draft)
    #expect(updated.activities.count == 1)
    let deleted = try await useCase.deleteActivity(timetableID: 354045, activityID: 17)
    #expect(deleted.activities.isEmpty)
    #expect(Array(stub.targets.suffix(3)).map(\.method) == [.delete, .get, .get])
  }

  @Test func overlapDoesNotSendMutation() async throws {
    let stub = ActivityAPIStub { target in
      if case .fetchTable = target { return (200, #"{"lectures":[]}"#) }
      return (200, blocks)
    }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    await #expect(throws: TimetableActivityError.self) {
      try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: draft)
    }
    #expect(stub.targets.allSatisfy { $0.method == .get })
  }

  @Test func refreshFailureAfterSaveDoesNotResubmitAndInvalidatesCache() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .createActivity: state.mutated = true; return (201, "")
      case .fetchTable: return (200, #"{"lectures":[]}"#)
      default: return state.mutated ? (503, "") : (200, #"{"custom_blocks":[]}"#)
      }
    }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    do {
      _ = try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: draft)
      Issue.record("Expected refresh failure")
    } catch TimetableActivityError.refreshRequired { }
    #expect(cache.timetable(forKey: "354045") == nil)
    #expect(stub.targets.filter { $0.method == .post }.count == 1)
  }

  @Test func fetchDoesNotReturnStaleCacheWhenOnlineAndFallsBackWhenUnavailable() async throws {
    let cache = try makeCache()
    cache.store(Timetable(id: "354045", lectures: []), forKey: "354045")
    let available = ActivityAPIStub { target in
      if case .fetchTable = target { return (200, #"{"lectures":[]}"#) }
      return (200, blocks)
    }
    let online = TimetableUseCase(otlTimetableRepository: available.repository, cache: cache)
    #expect(try await online.getTable(id: 354045).activities.count == 1)
    let unavailable = ActivityAPIStub { _ in (503, "") }
    let offline = TimetableUseCase(otlTimetableRepository: unavailable.repository, cache: cache)
    #expect(try await offline.getTable(id: 354045).activities.count == 1)
    let widget = TimetableUseCaseBackground(otlTimetableRepository: unavailable.repository, cache: cache)
    #expect(await widget.getTable(timetableID: 354045).activities.count == 1)
  }

  @Test func legacyCacheDecodesWithoutActivities() throws {
    let data = Data(#"{"id":"354045","lectures":[],"defaultMinMinutes":540,"defaultMaxMinutes":1080}"#.utf8)
    let table = try JSONDecoder().decode(Timetable.self, from: data)
    #expect(table.activities.isEmpty)
  }

  private func makeCache() throws -> TimetableCache {
    TimetableCache(modelContainer: try ModelContainer(for: CachedTimetable.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
  }
}

private final class ActivityAPIState: @unchecked Sendable {
  private let lock = NSLock()
  private var value = false
  var mutated: Bool {
    get { lock.withLock { value } }
    set { lock.withLock { value = newValue } }
  }
}

private final class ActivityAPIStub: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [OTLTimetableTarget] = []
  let response: @Sendable (OTLTimetableTarget) -> (Int, String)
  var targets: [OTLTimetableTarget] { lock.withLock { recorded } }
  var paths: [String] { targets.map(\.path) }

  init(response: @escaping @Sendable (OTLTimetableTarget) -> (Int, String)) { self.response = response }

  var repository: OTLTimetableRepository {
    let provider = MoyaProvider<OTLTimetableTarget>(endpointClosure: { target in
      self.lock.withLock { self.recorded.append(target) }
      let (status, body) = self.response(target)
      return Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(status, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub)
    return OTLTimetableRepository(provider: provider)
  }
}
