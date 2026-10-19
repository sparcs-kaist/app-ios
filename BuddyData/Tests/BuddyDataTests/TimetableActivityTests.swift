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
  private let multiTimeDraft = TimetableActivityDraft(title: "Study", location: "Library", times: [
    .init(day: .mon, begin: 600, end: 660),
    .init(day: .fri, begin: 840, end: 900),
  ])
  private let multiTimeBlocks = #"""
    {"custom_blocks":[{"id":17,"block_name":"Study","place":"Library","day":0,"begin":600,"end":660,
    "times":[{"day":0,"begin":600,"end":660},{"day":4,"begin":840,"end":900}]}]}
    """#
  private let applied = #"{"timetableItems":[],"results":[{"index":0,"kind":"custom","id":17}]}"#

  private func changes(_ target: OTLTimetableTarget) -> [[String: Any]]? {
    guard case .requestParameters(let payload, _) = target.task else { return nil }
    return payload["changes"] as? [[String: Any]]
  }

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

  @Test func everyMutationGoesThroughTheItemsBatch() async throws {
    let stub = ActivityAPIStub { _ in (200, applied) }
    let repository = stub.repository
    try await repository.createActivity(timetableID: 354045, draft: draft)
    try await repository.updateActivity(timetableID: 354045, activityID: 17, draft: draft)
    try await repository.deleteActivity(timetableID: 354045, activityID: 17)
    try await repository.addLecture(timetableID: 354045, lectureID: 5)
    try await repository.deleteLecture(timetableID: 354045, lectureID: 5)
    #expect(stub.targets.allSatisfy { $0.method == .patch })
    #expect(Set(stub.paths) == ["/api/v2/timetables/354045/items"])

    let sent = stub.targets.compactMap(changes).map { $0.first ?? [:] }
    #expect(sent.map { "\($0["op"] ?? "")/\($0["kind"] ?? "")" }
            == ["add/custom", "update/custom", "remove/custom", "add/lecture", "remove/lecture"])
    #expect(sent[1]["id"] as? Int == 17 && sent[2]["id"] as? Int == 17)
    #expect(sent[3]["lectureId"] as? Int == 5 && sent[4]["id"] as? Int == 5)
    for change in sent.prefix(2) {
      let data = change["data"] as? [String: Any] ?? [:]
      #expect(data["block_name"] as? String == "Study")
      #expect(data["place"] as? String == "Library")
      #expect(data["times"] as? [[String: Int]] == [["day": 3, "begin": 1020, "end": 1170]])
      #expect(data.count == 3)
    }
  }

  @Test func replacingIsOneBatchAndReportsTheItemsInOrder() async throws {
    let stub = ActivityAPIStub { _ in
      (200, #"{"timetableItems":[],"results":[{"index":1,"kind":"lecture","id":5},{"index":0,"kind":"custom","id":17}]}"#)
    }
    let ids = try await stub.repository.updateItems(
      timetableID: 354045,
      changes: [.removeActivity(activityID: 17), .addLecture(lectureID: 5)]
    )
    #expect(ids == [17, 5])
    #expect(stub.targets.count == 1)
    #expect(stub.targets.first.flatMap(changes)?.count == 2)
  }

  @Test func serverOverlapsReadAsOverlaps() async throws {
    // The server checks times this client can't see, and refuses the whole batch.
    let stub = ActivityAPIStub { _ in (409, #"{"message":"Timetable items overlap"}"#) }
    await #expect(throws: TimetableActivityError.overlap) {
      try await stub.repository.addLecture(timetableID: 354045, lectureID: 5)
    }
  }

  @Test func decodesEveryTimeRange() async throws {
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: (200, #"{"lectures":[]}"#)
      default: (200, multiTimeBlocks)
      }
    }
    let result = try await TimetableUseCase(otlTimetableRepository: stub.repository).getTable(id: 354045)
    #expect(result.activities.first?.times == multiTimeDraft.times)
    #expect(result.activities.first?.draft == multiTimeDraft)
  }

  @Test func mutationsSendEveryTimeRange() async throws {
    let stub = ActivityAPIStub { _ in (200, applied) }
    try await stub.repository.createActivity(timetableID: 354045, draft: multiTimeDraft)
    let data = stub.targets.first.flatMap(changes)?.first?["data"] as? [String: Any]
    #expect(data?["times"] as? [[String: Int]] == [
      ["day": 0, "begin": 600, "end": 660],
      ["day": 4, "begin": 840, "end": 900],
    ])
  }

  @Test func secondaryTimeRangesConflict() async throws {
    // Friday 14:30 overlaps only the block's second range.
    let friday = TimetableActivityDraft(title: "Gym", location: "", day: .fri, begin: 870, end: 930)
    let stub = ActivityAPIStub { target in
      if case .fetchTable = target { return (200, #"{"lectures":[]}"#) }
      return (200, multiTimeBlocks)
    }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    await #expect(throws: TimetableActivityError.overlap) {
      try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: friday)
    }
    #expect(stub.targets.allSatisfy { $0.method == .get })
  }

  @Test func draftsRejectTimesThatOverlapEachOther() {
    var draft = multiTimeDraft
    #expect(draft.isValid)
    draft.times.append(.init(day: .mon, begin: 630, end: 700))
    #expect(!draft.isValid)
    draft.times = []
    #expect(!draft.isValid)
  }

  @Test func activitiesRoundTripAndDecodeSingleRangeCaches() throws {
    let activity = TimetableActivity(id: 17, title: "Study", location: "Library", times: multiTimeDraft.times)
    let encoded = try JSONEncoder().encode(activity)
    #expect(try JSONDecoder().decode(TimetableActivity.self, from: encoded) == activity)
    let legacy = Data(#"{"id":17,"title":"Study","location":"Library","day":3,"begin":1020,"end":1170}"#.utf8)
    #expect(try JSONDecoder().decode(TimetableActivity.self, from: legacy).draft == draft)
  }

  @Test func saveAlwaysRefetchesAndUsesServerResult() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: return (200, #"{"lectures":[]}"#)
      case .updateItems: state.mutated = true; return (200, applied)
      case .fetchActivities: return (200, state.mutated ? blocks : #"{"custom_blocks":[]}"#)
      default: return (500, "")
      }
    }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    let result = try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: draft)
    #expect(result.activities.first?.id == 17)
    #expect(cache.timetable(forKey: "354045")?.activities == result.activities)
    #expect(stub.targets.map(\.method) == [.get, .get, .patch, .get, .get])
  }

  @Test func editingExcludesItselfAndDeletingRefetches() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: return (200, #"{"lectures":[]}"#)
      case .fetchActivities: return (200, state.mutated ? #"{"custom_blocks":[]}"# : blocks)
      case .updateItems(_, let changes):
        if changes == [.removeActivity(activityID: 17)] { state.mutated = true }
        return (200, applied)
      default: return (500, "")
      }
    }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    let updated = try await useCase.saveActivity(timetableID: 354045, activityID: 17, draft: draft)
    #expect(updated.activities.count == 1)
    let deleted = try await useCase.deleteActivity(timetableID: 354045, activityID: 17)
    #expect(deleted.activities.isEmpty)
    #expect(Array(stub.targets.suffix(3)).map(\.method) == [.patch, .get, .get])
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
      case .updateItems: state.mutated = true; return (200, applied)
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
    #expect(stub.targets.filter { $0.method == .patch }.count == 1)
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
