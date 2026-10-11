import Testing
import Foundation
import SwiftData
import Synchronization
import Moya
import BuddyDomain
@testable import BuddyDataCore

// MARK: - Fixtures

private func date(_ iso: String) -> Date {
  try! Date(iso, strategy: .iso8601)
}

/// Autumn 2026: Tuesday 1 September to Friday 18 December, in KST.
private let autumn2026 = Semester(
  year: 2026,
  semesterType: .autumn,
  beginDate: date("2026-08-31T15:00:00Z"),
  endDate: date("2026-12-18T14:59:00Z"),
  eventDate: SemesterEventDate(
    registrationPeriodStartDate: date("2026-08-10T01:00:00Z"),
    registrationPeriodEndDate: date("2026-08-14T08:00:00Z"),
    addDropPeriodEndDate: date("2026-09-11T14:59:00Z"),
    dropDeadlineDate: date("2026-10-23T14:59:00Z"),
    evaluationDeadlineDate: nil,
    gradePostingDate: nil
  )
)

private func lecture(id: Int, name: String, classes: [LectureClass]) -> Lecture {
  let base = Lecture.mock
  return Lecture(
    id: id, courseID: base.courseID, section: base.section, name: name, subtitle: base.subtitle,
    code: "CS.\(id)", department: base.department, type: base.type, capacity: base.capacity,
    enrolledCount: base.enrolledCount, credit: 3, creditAU: 0, grade: base.grade, load: base.load,
    speech: base.speech, isEnglish: base.isEnglish, professors: [Professor(id: 1, name: "Jane Doe")],
    classes: classes, exams: [], classDuration: base.classDuration, expDuration: base.expDuration
  )
}

private func lectureClass(_ day: DayType, _ begin: Int, _ end: Int) -> LectureClass {
  LectureClass(day: day, begin: begin, end: end, buildingCode: "E3-1", buildingName: "Computing Building", roomName: "1501")
}

private actor StubTimetables: TimetableUseCaseBackgroundProtocol {
  var semester: Semester?
  var tables: [Int: Timetable]
  var myTable: Timetable
  var list: [SemesterWithTimetables]

  init(semester: Semester?, tables: [Int: Timetable] = [:], myTable: Timetable, list: [SemesterWithTimetables] = []) {
    self.semester = semester
    self.tables = tables
    self.myTable = myTable
    self.list = list
  }

  func getCurrentMyTable() async -> Timetable { myTable }
  func getMyTable(year: Int, semester: SemesterType) async -> Timetable { myTable }
  func getTable(timetableID: Int) async -> Timetable { tables[timetableID] ?? Timetable(id: "\(timetableID)", lectures: []) }
  private(set) var tableListCalls = 0
  func getTableList() async -> [SemesterWithTimetables] {
    tableListCalls += 1
    return list
  }
  func getCurrentSemester() async -> Semester? { semester }
}

private final class IndexingSpy: TimetableIndexingServiceProtocol {
  let reindexCount = Mutex(0)
  func scheduleReindex() { reindexCount.withLock { $0 += 1 } }
  func clear() async {}
}

// MARK: - Event building

@Suite("Timetable events for Siri")
struct ClassEventBuilderTests {
  private let systemProgramming = lecture(id: 101, name: "System Programming",
                                          classes: [lectureClass(.mon, 540, 630), lectureClass(.tue, 780, 870)])

  @Test func weekdayMappingRoundTrips() {
    #expect(ClassEventBuilder.weekday(of: .sun) == 1)
    #expect(ClassEventBuilder.weekday(of: .mon) == 2)
    #expect(ClassEventBuilder.weekday(of: .sat) == 7)
    for day in DayType.allCases {
      #expect(ClassEventBuilder.day(ofWeekday: ClassEventBuilder.weekday(of: day)) == day)
    }
  }

  @Test func classesStartOnTheirFirstWeekdayInKAISTTime() {
    let events = ClassEventBuilder.events(for: Timetable(id: "1", lectures: [systemProgramming]),
                                          timetableID: nil, semester: autumn2026)
    #expect(events.count == 2)
    // The semester starts on a Tuesday, so Tuesday's class is that day and Monday's the next week.
    #expect(events[0].startDate == date("2026-09-01T04:00:00Z"))   // Tue 13:00 KST
    #expect(events[0].endDate == date("2026-09-01T05:30:00Z"))
    #expect(events[1].startDate == date("2026-09-07T00:00:00Z"))   // Mon 09:00 KST
    #expect(events.allSatisfy { $0.title == "System Programming" && !$0.isAllDay })
    #expect(events[0].location == "E3-1 1501, Computing Building")
    #expect(events[0].note?.hasPrefix("CS.101 · Jane Doe") == true)
  }

  @Test func classesRepeatWeeklyUntilTheSemesterEnds() {
    let event = ClassEventBuilder.events(for: Timetable(id: "1", lectures: [systemProgramming]),
                                         timetableID: nil, semester: autumn2026)[0]
    let expected = Calendar.RecurrenceRule.weekly(calendar: .kaist, end: .afterDate(autumn2026.endDate))
    #expect(event.recurrence == expected)
  }

  @Test func ignoresTheDeviceTimeZone() {
    var losAngeles = Calendar(identifier: .gregorian)
    losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    let kaist = ClassEventBuilder.firstOccurrence(of: .mon, minute: 540, onOrAfter: autumn2026.beginDate)
    let device = ClassEventBuilder.firstOccurrence(of: .mon, minute: 540, onOrAfter: autumn2026.beginDate,
                                                   calendar: losAngeles)
    #expect(kaist == date("2026-09-07T00:00:00Z"))
    #expect(kaist != device)
  }

  @Test func activitiesCarryTheirTableInTheIdentifier() {
    var table = Timetable(id: "42", lectures: [])
    table.activities = [TimetableActivity(id: 17, title: "Gym", location: " ", day: .fri, begin: 900, end: 960)]
    let event = ClassEventBuilder.events(for: table, timetableID: 42, semester: autumn2026)[0]
    #expect(event.id == "act:42:17")
    #expect(event.kind == .activity(timetableID: 42, activityID: 17))
    #expect(event.location == nil)
    #expect(event.startDate == date("2026-09-04T06:00:00Z"))   // Fri 15:00 KST
    let onMyTable = ClassEventBuilder.events(for: table, timetableID: nil, semester: autumn2026)[0]
    #expect(onMyTable.kind == .activity(timetableID: nil, activityID: 17))
  }

  @Test func academicDatesAreAllDayAndSkipMissingDates() {
    let events = ClassEventBuilder.academicEvents(for: autumn2026)
    let ids = events.map(\.id)
    #expect(ids == ["acad:2026-Autumn:begin", "acad:2026-Autumn:registration", "acad:2026-Autumn:addDropEnd",
                    "acad:2026-Autumn:dropDeadline", "acad:2026-Autumn:end"])
    #expect(events.allSatisfy { $0.isAllDay && $0.kind == .academic && $0.calendar == .academic })
    let drop = events[3]
    #expect(drop.startDate == date("2026-10-22T15:00:00Z"))   // 23 October, KST
    #expect(drop.endDate == date("2026-10-23T15:00:00Z"))
    let registration = events[1]
    #expect(registration.startDate == date("2026-08-09T15:00:00Z"))
    #expect(registration.endDate == date("2026-08-14T15:00:00Z"))   // through 14 August
  }

  @Test func everyMeetingThroughTheSemesterIsItsOwnDatedEvent() {
    let meetings = ClassEventBuilder.occurrences(for: Timetable(id: "1", lectures: [systemProgramming]),
                                                 timetableID: nil, semester: autumn2026)
    let mondays = meetings.filter { $0.id.hasPrefix("lec:101:0:540-630@") }
    // 7 September to 14 December: 15 Mondays. Tuesdays run 1 September to 15 December: 16.
    #expect(mondays.count == 15)
    #expect(meetings.count == 31)
    #expect(mondays.first?.id == "lec:101:0:540-630@2026-09-07")
    #expect(mondays.first?.startDate == date("2026-09-07T00:00:00Z"))
    #expect(mondays.last?.id == "lec:101:0:540-630@2026-12-14")
    #expect(mondays.last?.startDate == date("2026-12-14T00:00:00Z"))
    #expect(meetings.allSatisfy { $0.recurrence == nil && $0.endDate.timeIntervalSince($0.startDate) == 90 * 60 })
    #expect(meetings.map(\.startDate) == meetings.map(\.startDate).sorted())
    #expect(Set(meetings.map(\.id)).count == meetings.count)
    #expect(meetings.allSatisfy { $0.kind == .lecture(lectureID: 101) })
  }

  @Test func searchTermsCoverHowStudentsAsk() {
    let academic = ClassEventBuilder.academicEvents(for: autumn2026)
    let end = academic.first { $0.id.hasSuffix(":end") }
    #expect(end?.keywords.contains("종강") == true)
    #expect(academic.first { $0.id.hasSuffix(":begin") }?.keywords.contains("개강") == true)
    #expect(academic.first { $0.id.hasSuffix(":dropDeadline") }?.keywords.contains("드랍") == true)
    let meeting = ClassEventBuilder.occurrences(for: Timetable(id: "1", lectures: [systemProgramming]),
                                                timetableID: nil, semester: autumn2026)[0]
    #expect(meeting.keywords.contains("수업") && meeting.keywords.contains("lecture"))
  }

  @Test func weeklyScheduleGroupsMatchingMeetings() {
    let sameSlot = lecture(id: 1, name: "OS", classes: [lectureClass(.wed, 540, 630), lectureClass(.mon, 540, 630)])
    #expect(ClassEventBuilder.weeklySchedule(of: sameSlot) == "\(DayType.mon.stringValue)/\(DayType.wed.stringValue) 09:00–10:30 · E3-1 1501")
    #expect(ClassEventBuilder.weeklySchedule(of: systemProgramming)
            == "\(DayType.mon.stringValue) 09:00–10:30 · E3-1 1501; \(DayType.tue.stringValue) 13:00–14:30 · E3-1 1501")
    #expect(ClassEventBuilder.weeklySchedule(of: lecture(id: 2, name: "Seminar", classes: [])) == "")
  }

  @Test func identifiersParseBackToTheirKind() {
    let lectureID = ClassEvent.lectureID(systemProgramming, systemProgramming.classes[0])
    #expect(lectureID == "lec:101:0:540-630")
    #expect(ClassEvent.kind(of: lectureID) == .lecture(lectureID: 101))
    #expect(ClassEvent.kind(of: "act:my:3") == .activity(timetableID: nil, activityID: 3))
    #expect(ClassEvent.kind(of: lectureID + "@2026-09-07") == .lecture(lectureID: 101))
    #expect(ClassEvent.kind(of: "act:42:3@2026-09-04") == .activity(timetableID: 42, activityID: 3))
    #expect(ClassEvent.kind(of: "acad:2026-Autumn:end") == .academic)
    #expect(ClassEvent.kind(of: "act:x:3") == nil)
    #expect(ClassEvent.kind(of: "lec:101") == nil)
    #expect(ClassEvent.kind(of: "") == nil)
  }
}

// MARK: - Active timetable

@Suite("Active timetable resolution")
struct ActiveTimetableResolverTests {
  private let myTable = Timetable(id: "2026-Autumn-myTable", lectures: [Lecture.mock])
  private let planB = Timetable(id: "42", lectures: [Lecture.mock])
  private let list = [SemesterWithTimetables(year: 2026, semester: .autumn,
                                             timetables: [TimetableHeader(id: 42, name: "Plan B")])]

  private func resolve(
    selection: TimetableSelectionStore.Selection?,
    tables: [Int: Timetable],
    semester: Semester? = autumn2026
  ) async -> ActiveTimetable? {
    let stub = StubTimetables(semester: semester, tables: tables, myTable: myTable, list: list)
    return await ActiveTimetableResolver(useCase: stub, selection: { selection }).resolve()
  }

  @Test func usesTheSelectedTableOfTheCurrentSemester() async {
    let active = await resolve(selection: .init(year: 2026, semester: .autumn, timetableID: 42), tables: [42: planB])
    #expect(active?.source == .userTable(id: 42, title: "Plan B"))
    #expect(active?.userTableID == 42)
    #expect(active?.timetable == planB)
  }

  @Test func fallsBackToMyTableWhenTheSelectionIsEmpty() async {
    let active = await resolve(selection: .init(year: 2026, semester: .autumn, timetableID: 42),
                               tables: [42: Timetable(id: "42", lectures: [])])
    #expect(active?.source == .myTable)
    #expect(active?.userTableID == nil)
    #expect(active?.timetable == myTable)
  }

  @Test func treatsATableWithOnlyActivitiesAsNotEmpty() async {
    var activitiesOnly = Timetable(id: "42", lectures: [])
    activitiesOnly.activities = [TimetableActivity(id: 1, title: "Gym", location: "", day: .mon, begin: 600, end: 660)]
    let active = await resolve(selection: .init(year: 2026, semester: .autumn, timetableID: 42), tables: [42: activitiesOnly])
    #expect(active?.userTableID == 42)
  }

  @Test func fallsBackToMyTableForAnotherSemester() async {
    let active = await resolve(selection: .init(year: 2026, semester: .spring, timetableID: 42), tables: [42: planB])
    #expect(active?.source == .myTable)
  }

  @Test func usesMyTableWhenMyTableIsSelectedOrNothingIs() async {
    #expect(await resolve(selection: .init(year: 2026, semester: .autumn, timetableID: nil), tables: [42: planB])?.source == .myTable)
    #expect(await resolve(selection: nil, tables: [42: planB])?.source == .myTable)
  }

  @Test func widgetsSkipTheTitleRequest() async {
    let stub = StubTimetables(semester: autumn2026, tables: [42: planB], myTable: myTable, list: list)
    let resolver = ActiveTimetableResolver(useCase: stub, selection: { .init(year: 2026, semester: .autumn, timetableID: 42) })
    let active = await resolver.resolve(includingTitle: false)
    #expect(active?.userTableID == 42)
    #expect(await stub.tableListCalls == 0)
    #expect(await resolver.resolve()?.title == "Plan B")
    #expect(await stub.tableListCalls == 1)
  }

  @Test func needsACurrentSemester() async {
    #expect(await resolve(selection: nil, tables: [:], semester: nil) == nil)
  }
}

// MARK: - Siri's write rules

@Suite("Siri timetable write rules")
struct ClassEventWritePolicyTests {
  @Test func newActivitiesNeedAUserTable() throws {
    #expect(throws: ClassEventWriteError.myTableIsReadOnly) {
      try ClassEventWritePolicy.tableForNewActivity(activeTableID: nil, calendar: .timetable)
    }
    #expect(throws: ClassEventWriteError.academicIsReadOnly) {
      try ClassEventWritePolicy.tableForNewActivity(activeTableID: 42, calendar: .academic)
    }
    #expect(try ClassEventWritePolicy.tableForNewActivity(activeTableID: 42, calendar: .timetable) == 42)
  }

  @Test func onlyActivitiesInUserTablesChange() throws {
    #expect(throws: ClassEventWriteError.lectureIsReadOnly) { try ClassEventWritePolicy.activity(for: .lecture(lectureID: 1)) }
    #expect(throws: ClassEventWriteError.academicIsReadOnly) { try ClassEventWritePolicy.activity(for: .academic) }
    #expect(throws: ClassEventWriteError.myTableIsReadOnly) {
      try ClassEventWritePolicy.activity(for: .activity(timetableID: nil, activityID: 3))
    }
    let target = try ClassEventWritePolicy.activity(for: .activity(timetableID: 42, activityID: 3))
    #expect(target.timetableID == 42 && target.activityID == 3)
  }

  @Test func draftsUseKAISTTimeAndDefaultToOneHour() throws {
    let draft = try ClassEventWritePolicy.draft(title: " Gym ", startDate: date("2026-10-16T06:00:00Z"),
                                                endDate: nil, location: "Sports Complex")
    #expect(draft == TimetableActivityDraft(title: "Gym", location: "Sports Complex", day: .fri, begin: 900, end: 960))
  }

  @Test func draftsAcceptWeeklyRepeats() throws {
    let weekly = Calendar.RecurrenceRule.weekly(calendar: .kaist)
    let draft = try ClassEventWritePolicy.draft(title: "Gym", startDate: date("2026-10-16T06:00:00Z"),
                                                endDate: date("2026-10-16T08:00:00Z"), location: nil, recurrence: weekly)
    #expect(draft.end == 1020)
  }

  @Test func draftsRefuseWhatAWeeklyActivityCannotBe() {
    let start = date("2026-10-16T06:00:00Z")
    #expect(throws: ClassEventWriteError.nonWeeklyRecurrence) {
      try ClassEventWritePolicy.draft(title: "Gym", startDate: start, endDate: nil, location: nil,
                                      recurrence: .daily(calendar: .kaist))
    }
    #expect(throws: ClassEventWriteError.nonWeeklyRecurrence) {
      try ClassEventWritePolicy.draft(title: "Gym", startDate: start, endDate: nil, location: nil,
                                      recurrence: .weekly(calendar: .kaist, interval: 2))
    }
    #expect(throws: ClassEventWriteError.allDayUnsupported) {
      try ClassEventWritePolicy.draft(title: "Gym", startDate: start, endDate: nil, location: nil, isAllDay: true)
    }
    #expect(throws: ClassEventWriteError.spansMultipleDays) {
      // 23:00 to 01:00 KST.
      try ClassEventWritePolicy.draft(title: "Gym", startDate: date("2026-10-16T14:00:00Z"),
                                      endDate: date("2026-10-16T16:00:00Z"), location: nil)
    }
    #expect(throws: TimetableActivityError.self) {
      try ClassEventWritePolicy.draft(title: "  ", startDate: start, endDate: nil, location: nil)
    }
  }

  @Test func oneWeekOnlyIsRefused() throws {
    #expect(throws: ClassEventWriteError.singleWeekUnsupported) {
      try ClassEventWritePolicy.requireEveryWeek(thisWeekOnly: true)
    }
    try ClassEventWritePolicy.requireEveryWeek(thisWeekOnly: false)
  }

  @Test func myTableRefusalHintsAtDuplicating() {
    #expect(ClassEventWriteError.myTableIsReadOnly.errorDescription?.contains("duplicate My Table") == true)
  }
}

// MARK: - Supporting changes

@Suite("Timetable Siri plumbing")
struct TimetableSiriPlumbingTests {
  @Test func widgetReferencesRoundTripAndKeepServerIDs() {
    #expect(TimetableReference(entityID: 42) == .table(id: 42))
    #expect(TimetableReference.table(id: 42).entityID == 42)
    let autumn = TimetableReference.myTable(year: 2026, semester: .autumn)
    #expect(autumn.entityID == -20263)
    #expect(TimetableReference(entityID: -20263) == autumn)
    for semester in [SemesterType.spring, .summer, .autumn, .winter] {
      let reference = TimetableReference.myTable(year: 2025, semester: semester)
      #expect(TimetableReference(entityID: reference.entityID) == reference)
    }
    #expect(TimetableReference(entityID: 0) == nil)
  }

  @Test func selectionMovesToTheSharedStoreOnce() throws {
    let old = UserDefaults(suiteName: "selection-old-\(UUID())")!
    let new = UserDefaults(suiteName: "selection-new-\(UUID())")!
    TimetableSelectionStore(defaults: old).save(semester: autumn2026, timetableID: 42)

    TimetableSelectionStore.migrate(from: old, to: new)
    #expect(TimetableSelectionStore(defaults: new).selection?.timetableID == 42)
    #expect(TimetableSelectionStore(defaults: old).selection == nil)

    // A selection already in the shared store wins over a stale one.
    TimetableSelectionStore(defaults: old).save(semester: autumn2026, timetableID: 7)
    TimetableSelectionStore.migrate(from: old, to: new)
    #expect(TimetableSelectionStore(defaults: new).selection?.timetableID == 42)
    #expect(TimetableSelectionStore(defaults: old).selection == nil)
  }

  @Test func myTableForAnySemesterIsCachedUnderTheAppsKey() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    let online = TimetableUseCaseBackground(otlTimetableRepository: repository { _ in self.response(#"{"lectures":[]}"#) },
                                            cache: cache)
    let fresh = await online.getMyTable(year: 2025, semester: .spring)
    #expect(cache.timetable(forKey: "2025-Spring-myTable") == fresh)

    let offline = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
    #expect(await offline.getMyTable(year: 2025, semester: .spring) == fresh)
    #expect(await offline.getMyTable(year: 2024, semester: .autumn).lectures.isEmpty)
  }

  @Test func currentSemesterSurvivesOffline() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    cache.storeCurrentSemester(autumn2026)
    let offline = TimetableUseCaseBackground(otlTimetableRepository: offlineRepository(), cache: cache)
    #expect(await offline.getCurrentSemester() == autumn2026)
  }

  @Test func cachedUseCaseReadsTheAppsCacheOnly() async throws {
    let cache = TimetableCache(modelContainer: try makeContainer())
    let planB = Timetable(id: "42", lectures: [Lecture.mock])
    cache.storeCurrentSemester(autumn2026)
    cache.storeSemesters([autumn2026])
    cache.storeTimetableSummaries([TimetableSummary(id: 42, title: "Plan B", year: 2026, semester: .autumn)],
                                  semester: autumn2026)
    cache.store(planB, forKey: "42")
    cache.store(Timetable(id: "my", lectures: [Lecture.mock]), forKey: "2026-Autumn-myTable")

    let useCase = CachedTimetableUseCase(cache: cache)
    #expect(await useCase.getCurrentSemester() == autumn2026)
    #expect(await useCase.getTable(timetableID: 42) == planB)
    #expect(await useCase.getMyTable(year: 2026, semester: .autumn).id == "my")
    #expect(await useCase.getTableList().first?.timetables == [TimetableHeader(id: 42, name: "Plan B")])

    let active = await ActiveTimetableResolver(
      useCase: useCase,
      selection: { .init(year: 2026, semester: .autumn, timetableID: 42) }
    ).resolve()
    #expect(active?.source == .userTable(id: 42, title: "Plan B"))
  }

  @Test func timetableChangesRequestAReindex() async throws {
    let spy = IndexingSpy()
    let useCase = TimetableUseCase(
      otlTimetableRepository: repository { target in
        if case .fetchActivities = target { return self.response(#"{"custom_blocks":[]}"#) }
        return self.response(#"{"lectures":[]}"#)
      },
      cache: TimetableCache(modelContainer: try makeContainer()),
      timetableIndexingService: spy
    )
    _ = try await useCase.refreshTable(id: 42)
    _ = try await useCase.refreshMyTable(semester: autumn2026)
    #expect(spy.reindexCount.withLock { $0 } == 2)
  }

  @Test func serialQueueRunsOperationsOneAtATimeInOrder() async {
    let queue = SerialTaskQueue()
    let log = Mutex<[String]>([])
    async let first: Void = queue.run {
      log.withLock { $0.append("first-start") }
      try? await _Concurrency.Task.sleep(for: .milliseconds(100))
      log.withLock { $0.append("first-end") }
    }
    // Submitted while the first is suspended mid-operation.
    try? await _Concurrency.Task.sleep(for: .milliseconds(20))
    async let second: Void = queue.run { log.withLock { $0.append("second") } }
    _ = await (first, second)
    #expect(log.withLock { $0 } == ["first-start", "first-end", "second"])
  }

  @Test func adapterReadsThroughTheAppsUseCase() async throws {
    let semesterJSON = #"{"year":2026,"semester":3,"beginning":"2026-09-01T00:00:00.000Z","end":"2026-12-20T00:00:00.000Z"}"#
    let app = TimetableUseCase(
      otlTimetableRepository: repository { target in
        switch target {
        case .fetchSemesters: return self.response("{\"semesters\":[\(semesterJSON)]}")
        case .fetchCurrentSemester: return self.response(semesterJSON)
        case .fetchTables: return self.response(#"{"timetables":[{"id":42,"name":"Plan B","year":2026,"semester":3,"timeTableOrder":0}]}"#)
        case .fetchActivities: return self.response(#"{"custom_blocks":[]}"#)
        default: return self.response(#"{"lectures":[]}"#)
        }
      },
      cache: TimetableCache(modelContainer: try makeContainer())
    )
    let adapter = TimetableUseCaseBackgroundAdapter(app)
    let current = await adapter.getCurrentSemester()
    #expect(current?.year == 2026 && current?.semesterType == .autumn)
    #expect(await adapter.getTableList() == [SemesterWithTimetables(year: 2026, semester: .autumn,
                                                                     timetables: [TimetableHeader(id: 42, name: "Plan B")])])
    #expect(await adapter.getTable(timetableID: 42).id == "42")
    // A semester the app doesn't know yields an empty table, not an error.
    #expect(await adapter.getMyTable(year: 2019, semester: .spring).lectures.isEmpty)
  }

  // MARK: Helpers

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
