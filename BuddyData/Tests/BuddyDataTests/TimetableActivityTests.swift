import Testing
import Foundation
import SwiftData
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Timetable activities")
struct TimetableActivityTests {
  private let draft = TimetableActivityDraft(title: "Study", location: "Library", day: .thu, begin: 1020, end: 1170)
  private let blocks = #"{"lectures":[],"customBlocks":[{"id":17,"block_name":"Study","place":"Library","day":3,"begin":1020,"end":1170}]}"#
  private let empty = #"{"lectures":[],"customBlocks":[]}"#
  private let multiTimeDraft = TimetableActivityDraft(title: "Study", location: "Library", times: [
    .init(day: .mon, begin: 600, end: 660),
    .init(day: .fri, begin: 840, end: 900),
  ])
  private let multiTimeBlocks = #"""
    {"lectures":[],"customBlocks":[{"id":17,"block_name":"Study","place":"Library","day":0,"begin":600,"end":660,
    "times":[{"day":0,"begin":600,"end":660},{"day":4,"begin":840,"end":900}]}]}
    """#
  /// What the grouped items endpoint answers with: the whole timetable after the change.
  private var applied: String { blocks }

  private func body(_ target: OTLTimetableTarget) -> [String: [String: Any]]? {
    guard case .requestParameters(let payload, _) = target.task else { return nil }
    return payload as? [String: [String: Any]]
  }

  @Test func decodesServerFieldsAndCachesActivities() async throws {
    let stub = ActivityAPIStub { _ in (200, blocks) }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    let result = try await useCase.getTable(id: 354045)
    #expect(result.activities.first?.id == 17)
    #expect(result.activities.first?.draft == draft)
    #expect(cache.timetable(forKey: "354045") == result)
    #expect(stub.paths == ["/api/v2/timetables/354045/items"])
    #expect(stub.targets.map(\.method) == [.get])
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

    let sent = stub.targets.compactMap(body)
    #expect(sent.count == 5)
    // Every group is present in every request, as the server requires.
    for groups in sent {
      #expect(Set(groups.keys) == ["adds", "deletes", "updates"])
      #expect(Set(groups["adds"]?.keys ?? [:].keys) == ["lectureIds", "customBlocks"])
      #expect(Set(groups["deletes"]?.keys ?? [:].keys) == ["lectureIds", "customBlockIds"])
      #expect(Set(groups["updates"]?.keys ?? [:].keys) == ["customBlocks"])
    }

    let added = sent[0]["adds"]?["customBlocks"] as? [[String: Any]] ?? []
    let updated = sent[1]["updates"]?["customBlocks"] as? [[String: Any]] ?? []
    #expect(added.count == 1 && added.first?["id"] == nil)
    #expect(updated.count == 1 && updated.first?["id"] as? Int == 17)
    for block in added + updated {
      #expect(block["block_name"] as? String == "Study")
      #expect(block["place"] as? String == "Library")
      #expect(block["times"] as? [[String: Int]] == [["day": 3, "begin": 1020, "end": 1170]])
    }
    #expect(sent[2]["deletes"]?["customBlockIds"] as? [Int] == [17])
    #expect(sent[3]["adds"]?["lectureIds"] as? [Int] == [5])
    #expect(sent[4]["deletes"]?["lectureIds"] as? [Int] == [5])
  }

  @Test func replacingIsOneBatch() async throws {
    let stub = ActivityAPIStub { _ in (200, empty) }
    try await stub.repository.updateItems(
      timetableID: 354045,
      changes: [.removeActivity(activityID: 17), .addLecture(lectureID: 5)]
    )
    #expect(stub.targets.count == 1)
    let sent = stub.targets.first.flatMap(body)
    #expect(sent?["deletes"]?["customBlockIds"] as? [Int] == [17])
    #expect(sent?["adds"]?["lectureIds"] as? [Int] == [5])
  }

  @Test func serverOverlapsReadAsOverlaps() async throws {
    // The server checks times this client can't see, and refuses the whole batch.
    let stub = ActivityAPIStub { _ in (409, #"{"message":"Timetable items overlap"}"#) }
    await #expect(throws: TimetableActivityError.overlap) {
      try await stub.repository.addLecture(timetableID: 354045, lectureID: 5)
    }
  }

  @Test func decodesEveryTimeRange() async throws {
    let stub = ActivityAPIStub { _ in (200, multiTimeBlocks) }
    let result = try await TimetableUseCase(otlTimetableRepository: stub.repository).getTable(id: 354045)
    #expect(result.activities.first?.times == multiTimeDraft.times)
    #expect(result.activities.first?.draft == multiTimeDraft)
  }

  @Test func mutationsSendEveryTimeRange() async throws {
    let stub = ActivityAPIStub { _ in (200, applied) }
    try await stub.repository.createActivity(timetableID: 354045, draft: multiTimeDraft)
    let added = stub.targets.first.flatMap(body)?["adds"]?["customBlocks"] as? [[String: Any]]
    #expect(added?.first?["times"] as? [[String: Int]] == [
      ["day": 0, "begin": 600, "end": 660],
      ["day": 4, "begin": 840, "end": 900],
    ])
  }

  @Test func secondaryTimeRangesConflict() async throws {
    // Friday 14:30 overlaps only the block's second range.
    let friday = TimetableActivityDraft(title: "Gym", location: "", day: .fri, begin: 870, end: 930)
    let stub = ActivityAPIStub { _ in (200, multiTimeBlocks) }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    await #expect(throws: TimetableActivityError.overlap) {
      try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: friday)
    }
    #expect(stub.targets.allSatisfy { $0.method == .get })
  }

  @Test func refreshFromBeforeAnEditDoesNotUndoIt() async throws {
    // The GET is slow and answers with the table from before the delete; the PATCH is quick.
    let provider = MoyaProvider<OTLTimetableTarget>(endpointClosure: { target in
      let body: String = if case .fetchTable = target { blocks } else { empty }
      return Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(200, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: { target in
      if case .fetchTable = target { return .delayed(seconds: 0.3) }
      return .immediate
    })
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: OTLTimetableRepository(provider: provider), cache: cache)

    async let refreshed = useCase.refreshTable(id: 354045)
    try await _Concurrency.Task.sleep(for: .milliseconds(50))
    let deleted = try await useCase.deleteActivity(timetableID: 354045, activityID: 17)
    #expect(deleted.activities.isEmpty)

    #expect(try await refreshed.activities.isEmpty)
    #expect(cache.timetable(forKey: "354045")?.activities.isEmpty == true)
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

  @Test func saveUsesTheTimetableTheServerAnswersWith() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: return (200, state.mutated ? blocks : empty)
      case .updateItems: state.mutated = true; return (200, applied)
      default: return (500, "")
      }
    }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    let result = try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: draft)
    #expect(result.activities.first?.id == 17)
    #expect(cache.timetable(forKey: "354045")?.activities == result.activities)
    // Validated against a fresh copy, then nothing more to fetch: the PATCH answer is the table.
    #expect(stub.targets.map(\.method) == [.get, .patch])
  }

  @Test func editingExcludesItselfAndDeletingUsesTheAnswer() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .fetchTable: return (200, state.mutated ? empty : blocks)
      case .updateItems(_, let changes):
        if changes == [.removeActivity(activityID: 17)] { state.mutated = true; return (200, empty) }
        return (200, applied)
      default: return (500, "")
      }
    }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    let updated = try await useCase.saveActivity(timetableID: 354045, activityID: 17, draft: draft)
    #expect(updated.activities.count == 1)
    let deleted = try await useCase.deleteActivity(timetableID: 354045, activityID: 17)
    #expect(deleted.activities.isEmpty)
    #expect(stub.targets.last?.method == .patch)
  }

  @Test func overlapDoesNotSendMutation() async throws {
    let stub = ActivityAPIStub { _ in (200, blocks) }
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository)
    await #expect(throws: TimetableActivityError.self) {
      try await useCase.saveActivity(timetableID: 354045, activityID: nil, draft: draft)
    }
    #expect(stub.targets.allSatisfy { $0.method == .get })
  }

  @Test func unreadableAnswerRefetchesOnce() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .updateItems: state.mutated = true; return (200, "")
      case .fetchTable: return (200, state.mutated ? blocks : empty)
      default: return (500, "")
      }
    }
    let result = try await TimetableUseCase(otlTimetableRepository: stub.repository)
      .saveActivity(timetableID: 354045, activityID: nil, draft: draft)
    #expect(result.activities.first?.id == 17)
    #expect(stub.targets.map(\.method) == [.get, .patch, .get])
  }

  @Test func lectureEditsUseTheAnswerToo() async throws {
    let stub = ActivityAPIStub { _ in (200, blocks) }
    let cache = try makeCache()
    let useCase = TimetableUseCase(otlTimetableRepository: stub.repository, cache: cache)
    let added = try await useCase.addLecture(timetableID: 354045, lectureID: 5)
    let replaced = try await useCase.applyChanges(timetableID: 354045, changes: [.addLecture(lectureID: 5)])
    let deleted = try await useCase.deleteLecture(timetableID: 354045, lectureID: 5)
    #expect([added, replaced, deleted].allSatisfy { $0.activities.first?.id == 17 })
    #expect(cache.timetable(forKey: "354045") == deleted)
    #expect(stub.targets.allSatisfy { $0.method == .patch })
  }

  @Test func refreshFailureAfterSaveDoesNotResubmitAndInvalidatesCache() async throws {
    let state = ActivityAPIState()
    let stub = ActivityAPIStub { target in
      switch target {
      case .updateItems: state.mutated = true; return (200, "")
      case .fetchTable: return state.mutated ? (503, "") : (200, empty)
      default: return (500, "")
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
    let available = ActivityAPIStub { _ in (200, blocks) }
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
