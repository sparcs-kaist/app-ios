import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Course search")
struct CourseSearchTests {
  @Test func keywordOnlySearchOmitsFilterParameters() throws {
    let request = CourseSearchRequest(keyword: "network", limit: 150, offset: 0)
    let items = try queryItems(for: request)

    #expect(items == [
      URLQueryItem(name: "keyword", value: "network"),
      URLQueryItem(name: "limit", value: "150"),
      URLQueryItem(name: "offset", value: "0"),
      URLQueryItem(name: "order", value: "code")
    ])
  }

  @Test func filtersEncodeAsRepeatedKeysWithPeriodAsTerm() throws {
    let filter = LectureSearchFilter(
      departmentIDs: [9947, 9945],
      classifications: [.mr],
      levels: [.graduate]
    )
    let request = CourseSearchRequest(keyword: "", filter: filter, period: .twoYears, limit: 150, offset: 150)
    let items = try queryItems(for: request)

    #expect(items == [
      URLQueryItem(name: "department", value: "9945"),
      URLQueryItem(name: "department", value: "9947"),
      URLQueryItem(name: "level", value: "500"),
      URLQueryItem(name: "level", value: "600"),
      URLQueryItem(name: "level", value: "700"),
      URLQueryItem(name: "level", value: "800"),
      URLQueryItem(name: "level", value: "900"),
      URLQueryItem(name: "limit", value: "150"),
      URLQueryItem(name: "offset", value: "150"),
      URLQueryItem(name: "order", value: "code"),
      URLQueryItem(name: "term", value: "2"),
      URLQueryItem(name: "type", value: "MR")
    ])
  }

  /// The query a real request would carry, sorted the way Alamofire's `URLEncoding` emits it.
  private func queryItems(for request: CourseSearchRequest) throws -> [URLQueryItem] {
    let target = OTLCourseTarget.searchCourse(request: .fromModel(model: request))
    let urlRequest = try MoyaProvider<OTLCourseTarget>.defaultEndpointMapping(for: target).urlRequest()
    let url = try #require(urlRequest.url)

    #expect(url.path == "/api/v2/courses")
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
  }
}
