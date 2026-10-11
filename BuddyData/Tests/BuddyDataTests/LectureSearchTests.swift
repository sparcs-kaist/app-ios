import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Lecture search")
struct LectureSearchTests {
  private let semester = Semester(
    year: 2026,
    semesterType: .autumn,
    beginDate: .distantPast,
    endDate: .distantFuture,
    eventDate: SemesterEventDate(
      registrationPeriodStartDate: nil,
      registrationPeriodEndDate: nil,
      addDropPeriodEndDate: nil,
      dropDeadlineDate: nil,
      evaluationDeadlineDate: nil,
      gradePostingDate: nil
    )
  )

  @Test func keywordOnlySearchOmitsFilterParameters() throws {
    let request = LectureSearchRequest(semester: semester, keyword: "system", limit: 100, offset: 0)
    let items = try queryItems(for: request)

    #expect(items == [
      URLQueryItem(name: "keyword", value: "system"),
      URLQueryItem(name: "limit", value: "100"),
      URLQueryItem(name: "offset", value: "0"),
      URLQueryItem(name: "semester", value: "3"),
      URLQueryItem(name: "year", value: "2026")
    ])
  }

  @Test func filtersEncodeAsRepeatedKeys() throws {
    let filter = LectureSearchFilter(
      departmentIDs: [9947, 9945],
      classifications: [.me, .mr],
      levels: [.level400, .level300]
    )
    let request = LectureSearchRequest(semester: semester, keyword: "", filter: filter, limit: 100, offset: 100)
    let items = try queryItems(for: request)

    #expect(items == [
      URLQueryItem(name: "department", value: "9945"),
      URLQueryItem(name: "department", value: "9947"),
      URLQueryItem(name: "level", value: "300"),
      URLQueryItem(name: "level", value: "400"),
      URLQueryItem(name: "limit", value: "100"),
      URLQueryItem(name: "offset", value: "100"),
      URLQueryItem(name: "semester", value: "3"),
      URLQueryItem(name: "type", value: "MR"),
      URLQueryItem(name: "type", value: "ME"),
      URLQueryItem(name: "year", value: "2026")
    ])
  }

  @Test func timeFilterSendsDayAndMinutes() throws {
    let time = LectureTimeFilter(day: .wed, begin: 600, end: 780)
    let request = LectureSearchRequest(semester: semester, keyword: "", time: time, limit: 100, offset: 0)
    let items = try queryItems(for: request)

    #expect(items.filter { ["day", "begin", "end"].contains($0.name) } == [
      URLQueryItem(name: "begin", value: "600"),
      URLQueryItem(name: "day", value: "2"),
      URLQueryItem(name: "end", value: "780")
    ])
  }

  @Test func partialTimeFilterOmitsUnsetParts() throws {
    let request = LectureSearchRequest(
      semester: semester, keyword: "", time: LectureTimeFilter(begin: 780), limit: 100, offset: 0
    )
    let names = try queryItems(for: request).map(\.name)

    #expect(names.contains("begin"))
    #expect(!names.contains("day"))
    #expect(!names.contains("end"))
  }

  @Test func graduateLevelExpandsToEveryLevelFrom500() {
    let filter = LectureSearchFilter(levels: [.graduate, .level400])
    let request = LectureSearchRequest(semester: semester, keyword: "", filter: filter, limit: 100, offset: 0)
    let dto = LectureSearchRequestDTO.fromModel(model: request)

    #expect(dto.level == [400, 500, 600, 700, 800, 900])
  }

  @Test func decodesDepartmentOptionsInServerOrder() async throws {
    let body = #"{"departments":[{"id":9945,"name":"School of Computing","code":"CS"},{"id":623,"name":"Physics","code":"PH"}]}"#
    let provider = MoyaProvider<OTLLectureTarget>(endpointClosure: { target in
      Endpoint(url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(200, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub)
    let useCase = LectureUseCase(otlLectureRepository: OTLLectureRepository(provider: provider))

    let options = try await useCase.fetchDepartmentOptions()

    #expect(OTLLectureTarget.fetchDepartmentOptions.path == "/api/v2/department-options")
    #expect(options == [
      DepartmentOption(id: 9945, name: "School of Computing", code: "CS"),
      DepartmentOption(id: 623, name: "Physics", code: "PH")
    ])
  }

  @Test func nextPageFoldsSplitCourseIntoExistingSection() {
    let first = [course(id: 1, lectureIDs: [10]), course(id: 2, lectureIDs: [20, 21])]
    let second = [course(id: 2, lectureIDs: [21, 22]), course(id: 3, lectureIDs: [30])]

    let merged = first.appending(page: second)

    #expect(merged.map(\.id) == [1, 2, 3])
    #expect(merged.map { $0.lectures.map(\.id) } == [[10], [20, 21, 22], [30]])
  }

  // MARK: - Helpers

  /// The query a real request would carry, sorted the way Alamofire's `URLEncoding` emits it.
  private func queryItems(for request: LectureSearchRequest) throws -> [URLQueryItem] {
    let target = OTLLectureTarget.searchLecture(request: .fromModel(model: request))
    let urlRequest = try MoyaProvider<OTLLectureTarget>.defaultEndpointMapping(for: target).urlRequest()
    let url = try #require(urlRequest.url)

    #expect(url.path == "/api/v2/lectures")
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
  }

  private func course(id: Int, lectureIDs: [Int]) -> CourseLecture {
    CourseLecture(
      id: id,
      name: "Course \(id)",
      code: "CS.\(id)",
      type: .me,
      lectures: lectureIDs.map(lecture(id:)),
      completed: false
    )
  }

  private func lecture(id: Int) -> Lecture {
    Lecture(
      id: id,
      courseID: 0,
      section: "A",
      name: "",
      subtitle: "",
      code: "",
      department: Department(id: 9945, name: "School of Computing"),
      type: .me,
      capacity: 0,
      enrolledCount: 0,
      credit: 3,
      creditAU: 0,
      grade: 0,
      load: 0,
      speech: 0,
      isEnglish: false,
      professors: [],
      classes: [],
      exams: [],
      classDuration: 0,
      expDuration: 0
    )
  }
}
