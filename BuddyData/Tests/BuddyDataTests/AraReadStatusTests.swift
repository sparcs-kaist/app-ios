import Testing
import BuddyDomain
@testable import BuddyDataCore

@Suite("Ara read status")
struct AraReadStatusTests {
  @Test(arguments: [
    ("N", AraPost.ReadStatus.unread),
    ("-", .read),
    ("U", .updated),
  ])
  func mapsServerCodes(code: String, expected: AraPost.ReadStatus) {
    #expect(AraPost.ReadStatus(rawValue: code) == expected)
  }

  @Test func ignoresUnknownCodes() {
    #expect(AraPost.ReadStatus(rawValue: "") == nil)
    #expect(AraPost.ReadStatus(rawValue: "R") == nil)
  }
}
