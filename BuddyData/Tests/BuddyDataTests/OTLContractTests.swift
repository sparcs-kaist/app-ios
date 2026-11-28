import Testing
import Foundation
import Moya
import BuddyDomain
@testable import BuddyDataCore

/// Request and response shapes that must match what otlplus-server and the web send.
@Suite("OTL contract")
struct OTLContractTests {
  @Test func writingAReviewSendsLectureID() throws {
    let target = OTLReviewTarget.writeReview(lectureID: 11, content: "Good", grade: 5, load: 4, speech: 3)
    let request = try MoyaProvider<OTLReviewTarget>.defaultEndpointMapping(for: target).urlRequest()
    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

    #expect(request.url?.path == "/api/v2/reviews")
    #expect(request.httpMethod == "POST")
    #expect(json["lectureId"] as? Int == 11)
    #expect(json["lecture"] == nil)
  }

  @Test func friendsDecodeBetweenSemesters() throws {
    // `hasScheduleNow` is null while no semester is running.
    let json = #"{"id":1,"name":"Sujin Park","isFavorite":true,"hasScheduleNow":null}"#
    let friend = try JSONDecoder().decode(FriendDTO.self, from: Data(json.utf8)).toModel()
    #expect(friend.hasScheduleNow == nil)
  }
}
