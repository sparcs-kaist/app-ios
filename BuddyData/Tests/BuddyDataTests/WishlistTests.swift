import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Wishlist")
struct WishlistTests {
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

  @Test func fetchAsksForTheSemester() throws {
    let target = OTLUserTarget.fetchWishlist(userID: 42, year: 2026, semester: 3)
    let request = try MoyaProvider<OTLUserTarget>.defaultEndpointMapping(for: target).urlRequest()
    let url = try #require(request.url)
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    #expect(url.path == "/api/v2/users/42/wishlist")
    #expect(request.httpMethod == "GET")
    #expect(Set(items) == [URLQueryItem(name: "year", value: "2026"), URLQueryItem(name: "semester", value: "3")])
  }

  @Test(arguments: [(true, "add"), (false, "delete")])
  func updateSendsLectureAndMode(isWishlisted: Bool, mode: String) throws {
    let target = OTLUserTarget.updateWishlist(userID: 42, lectureID: 1234, isWishlisted: isWishlisted)
    let request = try MoyaProvider<OTLUserTarget>.defaultEndpointMapping(for: target).urlRequest()
    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

    #expect(request.url?.path == "/api/v2/users/42/wishlist")
    #expect(request.httpMethod == "PATCH")
    #expect(json["lectureId"] as? Int == 1234)
    #expect(json["mode"] as? String == mode)
  }

  @Test func fetchedLecturesDropTheServersRatingSums() async throws {
    let body = #"""
    {"courses":[{"id":7,"name":"Data Structure","code":"CS.20006","type":"Major Required","completed":true,"lectures":[
      {"id":11,"courseId":7,"classNo":"A","name":"Data Structure","subtitle":"","code":"CS.20006",
       "department":{"id":132,"name":"School of Computing"},"type":"Major Required",
       "limitPeople":260,"numPeople":90,"credit":3,"creditAU":0,
       "averageGrade":1312.5,"averageLoad":1290,"averageSpeech":1300,"isEnglish":true,
       "professors":[{"id":1,"name":"Moon, Eun Young"}],"classes":[],"examTimes":[],
       "classDuration":3,"expDuration":0}]}]}
    """#
    let provider = MoyaProvider<OTLUserTarget>(endpointClosure: { target in
      Endpoint(
        url: target.baseURL.absoluteString + target.path,
        sampleResponseClosure: { .networkResponse(200, Data(body.utf8)) },
        method: target.method, task: target.task, httpHeaderFields: target.headers
      )
    }, stubClosure: MoyaProvider.immediatelyStub)

    let courses = try await OTLUserRepository(provider: provider).fetchWishlist(userID: 42, semester: semester)
    let lecture = try #require(courses.first?.lectures.first)

    #expect(courses.map(\.id) == [7])
    #expect(courses.first?.completed == true)
    #expect(lecture.id == 11)
    #expect(lecture.grade == 0 && lecture.load == 0 && lecture.speech == 0)
  }
}
