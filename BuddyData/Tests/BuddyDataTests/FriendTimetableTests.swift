import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Friend timetable")
struct FriendTimetableTests {
  private let autumn = FriendTimetableTerm(year: 2026, semester: .autumn)

  @Test func semestersAskForTheFriendship() throws {
    let request = try MoyaProvider<FriendTarget>
      .defaultEndpointMapping(for: .fetchSharedSemesters(friendID: 7)).urlRequest()
    #expect(request.url?.path == "/api/v2/friends/7/timetables/shared/semesters")
    #expect(request.httpMethod == "GET")
  }

  @Test func timetableAsksForTheSemester() throws {
    let request = try MoyaProvider<FriendTarget>
      .defaultEndpointMapping(for: .fetchSharedTimetable(friendID: 7, year: 2026, semester: 3)).urlRequest()
    let url = try #require(request.url)
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    #expect(url.path == "/api/v2/friends/7/timetables/shared")
    #expect(Set(items) == [URLQueryItem(name: "year", value: "2026"), URLQueryItem(name: "semester", value: "3")])
    #expect(request.value(forHTTPHeaderField: "Accept-Language") != nil)
  }

  @Test func semestersComeNewestFirst() async throws {
    let repository = stub(#"{"semesters":[{"year":2025,"semester":3},{"year":2026,"semester":1},{"year":2026,"semester":3}]}"#)
    let terms = try await repository.fetchSharedTimetableTerms(friendID: 7)
    #expect(terms == [
      autumn,
      FriendTimetableTerm(year: 2026, semester: .spring),
      FriendTimetableTerm(year: 2025, semester: .autumn),
    ])
  }

  @Test func sharedTimetableKeepsItsNameAndBlocks() async throws {
    let repository = stub(#"""
      {"lectures":[],"customBlocks":[{"id":17,"block_name":"Study","place":"Library","day":3,"begin":1020,"end":1170}],
       "year":2026,"semester":3,"timetableType":"timetable","timetableId":42,"name":"Plan B"}
      """#)
    let result = try await repository.fetchSharedTimetable(friendID: 7, term: autumn)
    #expect(result.term == autumn)
    #expect(result.source == .shared(name: "Plan B"))
    #expect(result.timetable.activities.map(\.id) == [17])
  }

  @Test func enrolledLecturesAreMarkedAsSuch() async throws {
    let repository = stub(#"""
      {"lectures":[],"customBlocks":[],"year":2026,"semester":3,
       "timetableType":"scholar","timetableId":null,"name":"Enrolled timetable"}
      """#)
    let result = try await repository.fetchSharedTimetable(friendID: 7, term: autumn)
    #expect(result.source == .enrolment)
    #expect(result.timetable.lectures.isEmpty)
  }

  @Test func lectureFriendsAskForTheLecture() throws {
    let request = try MoyaProvider<FriendTarget>
      .defaultEndpointMapping(for: .fetchLectureFriends(lectureID: 11)).urlRequest()
    #expect(request.url?.path == "/api/v2/friends/lectures/11/overlaps")
    #expect(request.httpMethod == "GET")
  }

  @Test func lectureFriendsKeepTheirSemester() async throws {
    let repository = stub(#"""
      {"sameLecture":[{"id":7,"name":"yoon inha","isFavorite":true,"timetable":{"id":42,"year":2026,"semester":3}}],
       "sameCourseOtherSemester":[{"id":8,"name":"Minho Kim","isFavorite":false,"timetable":{"id":null,"year":2025,"semester":1}}]}
      """#)
    let friends = try await repository.fetchLectureFriends(lectureID: 11)
    #expect(friends.sameLecture.map(\.friend.id) == [7])
    #expect(friends.sameLecture.first?.term == autumn)
    #expect(friends.sameCourse.first?.term == FriendTimetableTerm(year: 2025, semester: .spring))
    #expect(friends.sameCourse.first?.friend.hasScheduleNow == nil)
    #expect(!friends.isEmpty)
  }

  private func stub(_ body: String) -> FriendRepository {
    FriendRepository(provider: MoyaProvider<FriendTarget>(endpointClosure: { target in
      Endpoint(
        url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(200, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers
      )
    }, stubClosure: MoyaProvider.immediatelyStub))
  }
}
