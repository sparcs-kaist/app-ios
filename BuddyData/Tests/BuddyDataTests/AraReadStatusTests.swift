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

@Suite("Ara name type")
struct AraNameTypeTests {
  @Test(arguments: [
    (1, AraPostNicknameType.regular),
    (2, .anonymous),
    (4, .realName),
  ])
  func mapsServerCodes(code: Int, expected: AraPostNicknameType) {
    #expect(AraPostNicknameType(code: code) == expected)
  }

  @Test func ignoresUnknownCodes() {
    #expect(AraPostNicknameType(code: 0) == nil)
    #expect(AraPostNicknameType(code: 3) == nil)
  }
}
