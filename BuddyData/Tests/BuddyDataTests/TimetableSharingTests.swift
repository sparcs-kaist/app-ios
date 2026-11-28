import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Timetable sharing")
struct TimetableSharingTests {
  @Test func sharingATimetableSendsItsID() throws {
    let body = try body(of: .setSharedTimetable(year: 2026, semester: 3, timetableID: 42))
    #expect(body["year"] as? Int == 2026)
    #expect(body["semester"] as? Int == 3)
    #expect(body["timetableId"] as? Int == 42)
  }

  @Test func sharingEnrolledLecturesSendsNull() throws {
    let body = try body(of: .setSharedTimetable(year: 2026, semester: 3, timetableID: nil))
    #expect(body["timetableId"] is NSNull)
  }

  @Test func readsTheSharedTimetableInOrder() async throws {
    let repository = stub(#"""
      {"timetables":[
        {"id":43,"name":"Plan B","year":2026,"semester":3,"timeTableOrder":1,"isMain":false,"isShared":true},
        {"id":42,"name":"Plan A","year":2026,"semester":3,"timeTableOrder":0,"isMain":true,"isShared":false}]}
      """#)
    let sharing = try await repository.getSharing(year: 2026, semester: .autumn)
    #expect(sharing.timetables.map(\.id) == [42, 43])
    #expect(sharing.sharedTimetableID == 43)
  }

  @Test func sharedSemestersAreTheUsersOwn() async throws {
    let request = try MoyaProvider<OTLTimetableTarget>.defaultEndpointMapping(for: .fetchSharedSemesters).urlRequest()
    #expect(request.url?.path == "/api/v2/timetables/shared/semesters")
    #expect(request.httpMethod == "GET")
    let repository = stub(#"{"semesters":[{"year":2026,"semester":1},{"year":2026,"semester":3}]}"#)
    #expect(try await repository.getSharedSemesters() == [
      FriendTimetableTerm(year: 2026, semester: .autumn),
      FriendTimetableTerm(year: 2026, semester: .spring),
    ])
  }

  @Test func ownSharedTimetableAsksForTheSemester() async throws {
    let request = try MoyaProvider<OTLTimetableTarget>
      .defaultEndpointMapping(for: .fetchSharedTimetable(year: 2026, semester: 3)).urlRequest()
    let url = try #require(request.url)
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    #expect(url.path == "/api/v2/timetables/shared")
    #expect(request.httpMethod == "GET")
    #expect(Set(items) == [URLQueryItem(name: "year", value: "2026"), URLQueryItem(name: "semester", value: "3")])

    let repository = stub(#"""
      {"lectures":[],"customBlocks":[],"year":2026,"semester":3,
       "timetableType":"scholar","timetableId":null,"name":"Enrolled timetable"}
      """#)
    #expect(try await repository.getSharedTimetable(year: 2026, semester: .autumn).lectures.isEmpty)
  }

  @Test func noSharedTimetableMeansEnrolledLectures() async throws {
    let repository = stub(#"{"timetables":[{"id":42,"name":"Plan A","year":2026,"semester":3,"timeTableOrder":0,"isShared":false}]}"#)
    #expect(try await repository.getSharing(year: 2026, semester: .autumn).sharedTimetableID == nil)
  }

  private func body(of target: OTLTimetableTarget) throws -> [String: Any] {
    let request = try MoyaProvider<OTLTimetableTarget>.defaultEndpointMapping(for: target).urlRequest()
    #expect(request.url?.path == "/api/v2/timetables/shared")
    #expect(request.httpMethod == "PATCH")
    let data = try #require(request.httpBody)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private func stub(_ body: String) -> OTLTimetableRepository {
    OTLTimetableRepository(provider: MoyaProvider<OTLTimetableTarget>(endpointClosure: { target in
      Endpoint(
        url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(200, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers
      )
    }, stubClosure: MoyaProvider.immediatelyStub))
  }
}
